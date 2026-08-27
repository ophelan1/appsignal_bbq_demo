require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    build_catalogue!
    @session = {}
    @cart = Cart.new(@session)
  end

  test "starts empty" do
    assert_predicate @cart, :empty?
    assert_equal 0, @cart.count
    assert_equal 0, @cart.subtotal_cents
  end

  test "adding accumulates quantity" do
    assert_equal 2, @cart.add(@rub, 2)
    assert_equal 1, @cart.add(@rub, 1)
    assert_equal 3, @cart.quantity_of(@rub)
  end

  test "adding is clamped to available stock" do
    assert_equal 3, @cart.add(@scarce, 99)
    assert_equal 0, @cart.add(@scarce, 5), "a full line should add nothing more"
  end

  test "adding is clamped to the per-line maximum" do
    assert_equal Product::MAX_PER_LINE, @cart.add(@rub, 500)
  end

  test "a sold out product cannot be added" do
    assert_equal 0, @cart.add(@sold_out, 1)
    assert_predicate @cart, :empty?
  end

  test "zero and negative quantities are ignored" do
    assert_equal 0, @cart.add(@rub, 0)
    assert_equal 0, @cart.add(@rub, -3)
    assert_predicate @cart, :empty?
  end

  test "setting a quantity to zero removes the line" do
    @cart.add(@rub, 5)
    @cart.set(@rub, 0)
    assert_predicate @cart, :empty?
  end

  test "subtotal multiplies price by quantity" do
    @cart.add(@rub, 3)
    assert_equal 4350, @cart.subtotal_cents
  end

  test "shipping is charged below the threshold and free above it" do
    @cart.add(@rub, 1)
    assert_equal Order::SHIPPING_CENTS, @cart.shipping_cents
    assert_equal 1450 + 595, @cart.total_cents

    @cart.set(@rub, 6) # 8700 > 7500
    assert_equal 0, @cart.shipping_cents
    assert_equal 8700, @cart.total_cents
  end

  test "an empty cart is never charged shipping" do
    assert_equal 0, @cart.shipping_cents
    assert_equal 0, @cart.total_cents
  end

  test "vat is the inclusive portion of the total" do
    @cart.add(@rub, 6)
    assert_equal (8700 * 0.21 / 1.21).round, @cart.vat_cents
    assert_operator @cart.vat_cents, :<, @cart.total_cents
  end

  test "lines survive a round trip through the session" do
    @cart.add(@rub, 2)
    restored = Cart.new(@session)
    assert_equal 2, restored.quantity_of(@rub)
    assert_equal 2900, restored.subtotal_cents
  end

  test "products deleted since they were added are dropped" do
    @cart.add(@rub, 2)
    @cart.add(@scarce, 1)
    @scarce.destroy
    assert_equal 1, Cart.new(@session).lines.size
  end
end
