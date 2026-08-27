# Deliberately badly-behaved endpoints.
#
# A healthy demo app produces a flat line in APM, which is a terrible thing to
# put in front of a prospect. Each action here creates one specific, recognisable
# shape in AppSignal so you can point at it and explain what it means.
class DemoController < ApplicationController
  class BarbecueOnFireError < StandardError; end
  class SupplierTimeoutError < StandardError; end

  before_action { Appsignal.set_namespace("demo") if defined?(Appsignal) }

  def index
    @stats = {
      products: Product.count,
      reviews: Review.count,
      orders: Order.count,
      appsignal_active: appsignal_active?
    }
  end

  # Shows up as a slow request dominated by a single SQL event.
  def slow_query
    @rows = Appsignal.instrument("query.demo_slow", "Deliberately expensive report") do
      # A correlated subquery per row, over a cross join. Nothing sensible would
      # ever be written this way, which is rather the point.
      Product.find_by_sql(<<~SQL)
        SELECT p.id, p.name, p.price_cents,
               (SELECT COUNT(*) FROM reviews r WHERE r.product_id = p.id) AS review_count,
               (SELECT AVG(r2.rating) FROM reviews r2 WHERE r2.product_id = p.id) AS avg_rating,
               (SELECT COUNT(*) FROM order_items oi
                  JOIN orders o ON o.id = oi.order_id
                 WHERE oi.product_id = p.id) AS times_ordered
          FROM products p, reviews x, reviews y
         GROUP BY p.id
         ORDER BY times_ordered DESC, p.name ASC
      SQL
    end

    sleep(0.35) # stands in for the slow third-party call that usually follows
    render :slow_query
  end

  # One query for the products, then two more per product. The classic.
  def n_plus_one
    @products = Product.all.to_a # deliberately no includes
    @started = Time.current
    render :n_plus_one
  end

  # The same page written properly, for the side-by-side.
  def optimised
    @products = Product.includes(:category, :reviews).to_a
    @started = Time.current
    render :n_plus_one
  end

  # Uncaught: becomes a 500 and an error sample in AppSignal.
  def error
    Appsignal.add_tags(demo_scenario: "uncaught_exception") if defined?(Appsignal)

    raise BarbecueOnFireError,
          "The Ironside 1200 reached 640°C and the brisket is now charcoal"
  end

  # Caught and reported explicitly: the request still succeeds, but the error
  # is recorded. This is the pattern you want in real code.
  def handled_error
    begin
      raise SupplierTimeoutError, "Wood supplier did not respond within 5s"
    rescue SupplierTimeoutError => e
      if defined?(Appsignal)
        Appsignal.report_error(e) do
          Appsignal.set_namespace("demo")
          Appsignal.add_tags(demo_scenario: "handled_exception", supplier: "post-oak-co")
          Appsignal.add_custom_data(retry_in_seconds: 30, queue_depth: 4)
        end
      end
      @message = "Supplier timed out. Reported to AppSignal, customer never saw it."
    end

    render :handled_error
  end

  # Enqueues a job that always fails, so the Background namespace has content.
  def background_job
    count = params.fetch(:count, 3).to_i.clamp(1, 25)
    count.times { |i| StockReconciliationJob.perform_later(i) }

    redirect_to demo_path, notice: "Queued #{count} stock reconciliation jobs — some will fail on purpose."
  end

  # Outbound HTTP shows as its own event inside the request timeline.
  def external_http
    require "net/http"

    @result =
      begin
        uri = URI("https://api.github.com/zen")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end
        "#{response.code}: #{response.body.to_s.strip}"
      rescue StandardError => e
        Appsignal.report_error(e) if defined?(Appsignal)
        "Request failed: #{e.class} — #{e.message}"
      end

    render :external_http
  end

  # Allocation-heavy request, visible in the memory and allocation graphs.
  def memory_hog
    @allocated = Appsignal.instrument("allocate.demo", "Build a large throwaway array") do
      blob = Array.new(120_000) { |i| "smoke-ring-#{i}-#{'x' * 40}" }
      blob.each_slice(1_000).map(&:size).sum
    end

    render :memory_hog
  end

  # Counters, gauges and distributions, without needing real traffic.
  def custom_metric
    return render :custom_metric unless appsignal_active?

    Appsignal.increment_counter("demo_button_presses", 1, category: "manual")
    Appsignal.set_gauge("pit_temperature_celsius", rand(95..135))
    Appsignal.set_gauge("wood_remaining_kg", rand(2..15))
    Appsignal.add_distribution_value("cook_duration_minutes", rand(180..760))

    @sent = [
      "demo_button_presses (counter)",
      "pit_temperature_celsius (gauge)",
      "wood_remaining_kg (gauge)",
      "cook_duration_minutes (distribution)"
    ]

    render :custom_metric
  end

  private

  def appsignal_active?
    defined?(Appsignal) && Appsignal.respond_to?(:active?) && Appsignal.active?
  end
end
