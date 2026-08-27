# A session-backed cart. Not an Active Record model: carts live in the session
# until checkout, at which point they become a real Order.
class Cart
  Line = Struct.new(:product, :quantity, keyword_init: true) do
    def line_total_cents = product.price_cents * quantity
  end

  attr_reader :items

  def initialize(session)
    @session = session
    @items = (session[:cart] || {}).transform_values(&:to_i)
  end

  def add(product, quantity = 1)
    quantity = quantity.to_i
    return 0 if product.nil? || quantity <= 0

    ceiling = product.max_orderable
    return 0 if ceiling <= 0

    current = items.fetch(product.slug, 0)
    updated = [current + quantity, ceiling].min
    items[product.slug] = updated
    persist!
    updated - current
  end

  def set(product, quantity)
    quantity = quantity.to_i
    return remove(product) if quantity <= 0

    items[product.slug] = [quantity, product.max_orderable].min
    persist!
    items[product.slug]
  end

  def remove(product)
    items.delete(product.slug)
    persist!
    0
  end

  def clear
    @items = {}
    persist!
  end

  def empty?    = items.empty?
  def count     = items.values.sum
  def quantity_of(product) = items.fetch(product.slug, 0)

  # One query for the whole cart, not one per line.
  def lines
    @lines ||= begin
      products = Product.includes(:category).where(slug: items.keys).index_by(&:slug)
      items.filter_map do |slug, quantity|
        product = products[slug]
        next unless product

        Line.new(product: product, quantity: quantity)
      end
    end
  end

  def subtotal_cents = lines.sum(&:line_total_cents)

  def shipping_cents
    return 0 if subtotal_cents.zero? || subtotal_cents >= Order::FREE_SHIPPING_THRESHOLD_CENTS

    Order::SHIPPING_CENTS
  end

  def total_cents = subtotal_cents + shipping_cents

  def vat_cents = (total_cents * Order::VAT_RATE / (1 + Order::VAT_RATE)).round

  def cents_to_free_shipping
    remaining = Order::FREE_SHIPPING_THRESHOLD_CENTS - subtotal_cents
    remaining.positive? ? remaining : 0
  end

  private

  def persist!
    @lines = nil
    @session[:cart] = items
  end
end
