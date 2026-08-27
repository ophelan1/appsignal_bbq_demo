module ApplicationHelper
  CURRENCY_SYMBOL = "€".freeze

  HEAT_LABELS = ["no heat", "mild", "gentle warmth", "medium", "hot", "serious heat"].freeze

  CATEGORY_ART = {
    "grills" => { hue: 18,  glyph: :dome },
    "rubs"   => { hue: 32,  glyph: :shaker },
    "sauces" => { hue: 355, glyph: :bottle },
    "wood"   => { hue: 24,  glyph: :log },
    "tools"  => { hue: 200, glyph: :probe }
  }.freeze

  # Integer cents in, formatted money out. No float ever touches a total.
  def money(cents)
    cents = cents.to_i
    sign  = cents.negative? ? "-" : ""
    whole, part = cents.abs.divmod(100)
    grouped = whole.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
    "#{sign}#{CURRENCY_SYMBOL}#{grouped}.#{part.to_s.rjust(2, "0")}"
  end

  def heat_meter(level)
    level = level.to_i
    return "".html_safe if level.zero?

    dots = (1..5).map do |i|
      tag.span(class: i <= level ? "heat-dot on" : "heat-dot")
    end.join.html_safe

    tag.span(dots, class: "heat", title: HEAT_LABELS[level] || "hot")
  end

  def badge_tags(product)
    tags = []
    tags << tag.span("New", class: "badge badge-new") if product.new?
    tags << tag.span("Bestseller", class: "badge badge-best") if product.bestseller?
    tags << tag.span("Flagship", class: "badge badge-flag") if product.flagship?
    tags << tag.span("Only #{product.stock} left", class: "badge badge-low") if product.low_stock?
    tags << tag.span("Sold out", class: "badge badge-out") unless product.in_stock?
    safe_join(tags)
  end

  def stock_note(product)
    return "Sold out" unless product.in_stock?
    return "Only #{product.stock} left in the yard" if product.low_stock?

    "In stock"
  end

  def stock_class(product)
    return "stock-out" unless product.in_stock?
    return "stock-low" if product.low_stock?

    "stock-ok"
  end

  def rating_stars(rating)
    return tag.span("No reviews yet", class: "muted rating-none") if rating.nil?

    filled = rating.round
    stars = (1..5).map { |i| i <= filled ? "★" : "☆" }.join
    tag.span("#{stars} #{rating}", class: "rating")
  end

  def paragraphs(text)
    safe_join(text.to_s.split(/\n{2,}/).map { |p| tag.p(p.strip) })
  end

  # Deterministic inline SVG artwork, so the store needs no image hosting and
  # works with no network at all.
  def product_art(product, size: 320)
    art  = CATEGORY_ART.fetch(product.category.slug, { hue: 20, glyph: :dome })
    seed = Digest::MD5.hexdigest(product.slug)[0, 4].to_i(16)
    hue  = (art[:hue] + (seed % 26) - 13) % 360
    id   = "g#{Digest::MD5.hexdigest(product.slug)[0, 8]}"

    <<~SVG.html_safe
      <svg class="art" viewBox="0 0 320 240" width="#{size}" height="#{(size * 0.75).round}"
           role="img" aria-label="#{ERB::Util.html_escape(product.name)}" preserveAspectRatio="xMidYMid slice">
        <defs>
          <linearGradient id="#{id}" x1="0" y1="0" x2="0.6" y2="1">
            <stop offset="0%" stop-color="hsl(#{hue}, 42%, 26%)"/>
            <stop offset="100%" stop-color="hsl(#{(hue + 340) % 360}, 30%, 11%)"/>
          </linearGradient>
          <radialGradient id="#{id}e" cx="0.5" cy="0.85" r="0.7">
            <stop offset="0%" stop-color="hsl(#{hue}, 90%, 58%)" stop-opacity="0.55"/>
            <stop offset="100%" stop-color="hsl(#{hue}, 90%, 58%)" stop-opacity="0"/>
          </radialGradient>
        </defs>
        <rect width="320" height="240" fill="url(##{id})"/>
        <ellipse cx="160" cy="215" rx="150" ry="70" fill="url(##{id}e)"/>
        #{smoke_wisps(seed)}
        <g transform="translate(160 120)" fill="none" stroke="rgba(255,240,225,0.88)"
           stroke-width="6" stroke-linecap="round" stroke-linejoin="round">
          #{glyph_path(art[:glyph])}
        </g>
      </svg>
    SVG
  end

  private

  def smoke_wisps(seed)
    (0..2).map do |i|
      x = 40 + ((seed >> (i * 3)) % 240)
      o = 0.05 + (i * 0.03)
      %(<path d="M#{x} 240 C #{x - 30} 170, #{x + 34} 150, #{x - 6} 70" ) +
        %(stroke="rgba(255,255,255,#{o})" stroke-width="#{22 + (i * 10)}" fill="none" stroke-linecap="round"/>)
    end.join("\n")
  end

  def glyph_path(glyph)
    case glyph
    when :dome
      '<path d="M-52 24 A52 52 0 0 1 52 24 Z"/><line x1="-64" y1="24" x2="64" y2="24"/>' \
      '<line x1="-34" y1="24" x2="-46" y2="52"/><line x1="34" y1="24" x2="46" y2="52"/>' \
      '<path d="M0 -34 c10 12 -12 16 0 30" stroke-width="5"/>'
    when :shaker
      '<path d="M-26 -30 h52 v66 a10 10 0 0 1 -10 10 h-32 a10 10 0 0 1 -10 -10 Z"/>' \
      '<path d="M-20 -30 v-14 a20 20 0 0 1 40 0 v14"/>' \
      '<circle cx="-8" cy="-38" r="2.6" fill="rgba(255,240,225,0.9)" stroke="none"/>' \
      '<circle cx="8" cy="-38" r="2.6" fill="rgba(255,240,225,0.9)" stroke="none"/>'
    when :bottle
      '<path d="M-16 -46 h32 v20 l14 20 v52 a8 8 0 0 1 -8 8 h-44 a8 8 0 0 1 -8 -8 v-52 l14 -20 Z"/>' \
      '<line x1="-22" y1="14" x2="22" y2="14"/><path d="M-12 -46 v-8 h24 v8"/>'
    when :log
      '<ellipse cx="-18" cy="20" rx="16" ry="30" transform="rotate(-24 -18 20)"/>' \
      '<ellipse cx="20" cy="26" rx="16" ry="30" transform="rotate(28 20 26)"/>' \
      '<path d="M0 -46 c16 20 -18 26 0 46 18 -20 -16 -26 0 -46 Z" stroke-width="5"/>'
    when :probe
      '<line x1="-34" y1="46" x2="16" y2="-14"/>' \
      '<rect x="6" y="-52" width="42" height="30" rx="7" transform="rotate(45 27 -37)"/>' \
      '<line x1="-34" y1="46" x2="-42" y2="54" stroke-width="8"/>'
    else
      '<circle r="34"/>'
    end
  end
end
