require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup { build_catalogue! }

  def order_with_items(*pairs)
    order = Order.new(valid_order_params)
    pairs.each do |product, quantity|
      order.order_items.build(product: product, quantity: quantity, unit_cents: product.price_cents)
    end
    order.recalculate_totals!
    order
  end

  test "generates a reference on create" do
    order = order_with_items([@rub, 1])
    assert order.save
    assert_match(/\ASMK-[0-9A-F]{6}\z/, order.reference)
  end

  test "totals are derived from the line items" do
    order = order_with_items([@rub, 2], [@scarce, 1]) # 2900 + 6500
    assert_equal 9400, order.subtotal_cents
    assert_equal 0, order.shipping_cents, "over the free shipping threshold"
    assert_equal 9400, order.total_cents
    assert_equal (9400 * 0.21 / 1.21).round, order.vat_cents
  end

  test "shipping is added below the threshold" do
    order = order_with_items([@rub, 1])
    assert_equal Order::SHIPPING_CENTS, order.shipping_cents
    assert_equal 1450 + 595, order.total_cents
  end

  test "requires the details we actually ship to" do
    order = Order.new
    refute order.valid?
    %i[customer_name email address postcode city country].each do |field|
      assert order.errors[field].any?, "#{field} should be required"
    end
  end

  test "rejects a malformed email" do
    ["nope", "no@domain", "a b@c.com", "@example.com"].each do |bad|
      order = Order.new(valid_order_params.merge(email: bad))
      refute order.valid?, "#{bad.inspect} should be rejected"
      assert order.errors[:email].any?
    end
  end

  test "rejects a country we do not ship to" do
    order = Order.new(valid_order_params.merge(country: "Narnia"))
    refute order.valid?
    assert order.errors[:country].any?
  end

  test "references are unique across many orders" do
    references = 20.times.map { order_with_items([@rub, 1]).tap(&:save!).reference }
    assert_equal references.size, references.uniq.size
  end

  test "item count sums quantities" do
    assert_equal 3, order_with_items([@rub, 2], [@scarce, 1]).item_count
  end
end
