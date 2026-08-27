# Drives traffic at a running instance so an AppSignal dashboard has something
# on it before you start a demo.
#
# Start the server first, then in a second terminal:
#
#   bin/rails demo:traffic              # about two minutes of mixed traffic
#   bin/rails demo:traffic MINUTES=10
#   bin/rails demo:burst                # one of every scenario, fast
#
# Real HTTP against the real server, so every request goes through Puma and the
# full middleware stack exactly as a browser's would.
namespace :demo do
  DEMO_PATHS = [
    ["/demo/slow_query",    3],
    ["/demo/n_plus_one",    3],
    ["/demo/optimised",     2],
    ["/demo/external_http", 2],
    ["/demo/memory_hog",    1],
    ["/demo/custom_metric", 3],
    ["/demo/handled_error", 2],
    ["/demo/error",         1]
  ].freeze

  def base_uri
    URI(ENV.fetch("BASE_URL", "http://127.0.0.1:#{ENV.fetch("PORT", 3000)}"))
  end

  def storefront_paths
    slugs      = Product.pluck(:slug)
    categories = Category.pluck(:slug)
    [
      "/", "/", "/", "/cart", "/orders",
      *slugs.sample(8).map { |slug| "/products/#{slug}" },
      *categories.map { |slug| "/categories/#{slug}" },
      "/search?q=brisket", "/search?q=oak", "/search?q=rub", "/search?q=thermometer"
    ]
  end

  def check_server!(http)
    http.request(Net::HTTP::Get.new("/up"))
  rescue Errno::ECONNREFUSED
    abort <<~MESSAGE
      Could not reach #{base_uri}.

      Start the server first, in another terminal:
          bin/rails server

      Or point this task somewhere else:
          bin/rails demo:traffic BASE_URL=http://localhost:4000
    MESSAGE
  end

  # Rails protects the background-job endpoint with CSRF, exactly as it should.
  # So do what a browser does: fetch the page, keep the session cookie, and send
  # the authenticity token back with the POST.
  def post_with_csrf(http, path, form_data)
    page = http.request(Net::HTTP::Get.new("/demo"))
    cookie = page.get_fields("set-cookie").to_a.map { |c| c.split(";").first }.join("; ")
    token = page.body[/<meta name="csrf-token" content="([^"]+)"/, 1]

    request = Net::HTTP::Post.new(path)
    request["Cookie"] = cookie
    request.set_form_data(form_data.merge("authenticity_token" => token.to_s))
    http.request(request)
  end

  desc "Generate mixed traffic against a running server (MINUTES=2 by default)"
  task traffic: :environment do
    require "net/http"

    minutes  = Float(ENV.fetch("MINUTES", "2"))
    uri      = base_uri
    weighted = DEMO_PATHS.flat_map { |path, weight| [path] * weight }
    counts   = Hash.new(0)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.read_timeout = 30
      check_server!(http)

      puts "Driving traffic at #{uri} for #{minutes} minute(s). Ctrl-C to stop early."
      puts "AppSignal active: #{Appsignal.active?}"
      puts

      deadline = Time.current + (minutes * 60)
      requests = 0

      while Time.current < deadline
        path = rand < 0.7 ? storefront_paths.sample : weighted.sample

        begin
          response = http.request(Net::HTTP::Get.new(path))
          counts[response.code] += 1
        rescue StandardError => e
          counts[e.class.name] += 1
        end

        requests += 1

        # Every so often, queue background jobs as well.
        if (requests % 20).zero?
          begin
            post_with_csrf(http, "/demo/background_job", "count" => "4")
            counts["jobs"] += 4
          rescue StandardError => e
            counts[e.class.name] += 1
          end
        end

        print "\r  #{requests} requests — #{counts.map { |code, n| "#{code}:#{n}" }.join(" ")}   "
        sleep(rand(0.15..0.6))
      end

      puts
      puts
      puts "Done: #{requests} requests."
      puts "  #{counts.select { |code, _| code.start_with?("5") }.values.sum} server errors (deliberate)"
      puts "Give AppSignal a minute, then look at Performance, Errors and Background."
    end
  end

  desc "Fire one of every demo scenario once"
  task burst: :environment do
    require "net/http"

    uri = base_uri
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.read_timeout = 30
      check_server!(http)

      puts "AppSignal active: #{Appsignal.active?}"
      DEMO_PATHS.each do |path, _weight|
        print "  #{path.ljust(24)} "
        response = http.request(Net::HTTP::Get.new(path))
        puts response.code == "500" ? "500 (deliberate)" : response.code
      end

      print "  #{"/demo/background_job".ljust(24)} "
      puts post_with_csrf(http, "/demo/background_job", "count" => "6").code
    end

    puts "Done."
  end

  desc "Show what the app knows about itself"
  task status: :environment do
    puts "Products:  #{Product.count}"
    puts "Reviews:   #{Review.count}"
    puts "Orders:    #{Order.count}"
    puts "AppSignal: #{Appsignal.active? ? "active" : "inactive (no APPSIGNAL_PUSH_API_KEY set)"}"
    puts "Base URL:  #{base_uri}"
  end
end
