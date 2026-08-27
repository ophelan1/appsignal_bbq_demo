require "test_helper"

class StorefrontTest < ActionDispatch::IntegrationTest
  setup { build_catalogue! }

  test "storefront renders" do
    get root_path
    assert_response :success
    assert_select "h1"
    assert_match "Blackened Brisket Rub", response.body
  end

  test "product page renders with its price" do
    get product_path(@rub.slug)
    assert_response :success
    assert_match "Blackened Brisket Rub", response.body
    assert_match "€14.50", response.body
  end

  test "unknown product returns 404" do
    get product_path("no-such-thing")
    assert_response :not_found
  end

  test "category page shows only that category" do
    get category_path("rubs")
    assert_response :success
    assert_match "Blackened Brisket Rub", response.body
    refute_match "Brisket Slicer", response.body
  end

  test "unknown category returns 404" do
    get category_path("nonsense")
    assert_response :not_found
  end

  test "search finds products and escapes the query" do
    get search_path, params: { q: "brisket" }
    assert_response :success
    assert_match "Blackened Brisket Rub", response.body

    get search_path, params: { q: "<script>alert(1)</script>" }
    assert_response :success
    refute_match "<script>alert(1)</script>", response.body
  end

  test "empty search returns no results rather than everything" do
    get search_path, params: { q: "" }
    assert_response :success
    assert_match "Nothing matched that", response.body
  end

  test "health endpoint reports json" do
    get health_path
    assert_response :success
    assert_equal "ok", JSON.parse(response.body)["status"]
  end
end

class CartFlowTest < ActionDispatch::IntegrationTest
  setup { build_catalogue! }

  test "adding to the cart persists across requests" do
    post cart_add_path, params: { slug: @rub.slug, quantity: 2 }
    assert_redirected_to cart_path

    get cart_path
    assert_response :success
    assert_match "Blackened Brisket Rub", response.body
    assert_match "€29.00", response.body
  end

  test "return_to is honoured for local paths" do
    post cart_add_path, params: { slug: @rub.slug, return_to: "/categories/rubs" }
    assert_redirected_to "/categories/rubs"
  end

  test "return_to cannot redirect off site" do
    post cart_add_path, params: { slug: @rub.slug, return_to: "https://evil.example.com" }
    assert_redirected_to cart_path
  end

  test "protocol relative return_to is rejected" do
    post cart_add_path, params: { slug: @rub.slug, return_to: "//evil.example.com" }
    assert_redirected_to cart_path, "protocol-relative open redirect"
  end

  test "stock ceiling is enforced through the controller" do
    post cart_add_path, params: { slug: @scarce.slug, quantity: 99 }
    get cart_path
    assert_match "value=\"3\"", response.body
  end

  test "updating and removing a line" do
    post cart_add_path, params: { slug: @rub.slug, quantity: 3 }
    patch cart_update_path, params: { slug: @rub.slug, quantity: 1 }
    get cart_path
    assert_match "€14.50", response.body

    delete cart_remove_path, params: { slug: @rub.slug }
    get cart_path
    assert_match "Your cart is cold", response.body
  end

  test "checkout redirects to the cart when empty" do
    get checkout_path
    assert_redirected_to cart_path
  end

  test "a valid checkout creates an order and clears the cart" do
    post cart_add_path, params: { slug: @rub.slug, quantity: 2 }

    assert_difference -> { Order.count }, 1 do
      post checkout_path, params: { order: valid_order_params }
    end

    order = Order.last
    assert_redirected_to order_path(order.reference)
    assert_equal 2900, order.subtotal_cents
    assert_equal 1, order.order_items.size

    get cart_path
    assert_match "Your cart is cold", response.body
  end

  test "an invalid checkout is rejected and keeps the cart" do
    post cart_add_path, params: { slug: @rub.slug, quantity: 2 }

    assert_no_difference -> { Order.count } do
      post checkout_path, params: { order: valid_order_params.merge(email: "nope") }
    end

    assert_response :unprocessable_entity

    get cart_path
    assert_match "Blackened Brisket Rub", response.body
  end

  test "checkout queues a confirmation job" do
    post cart_add_path, params: { slug: @rub.slug, quantity: 1 }

    assert_enqueued_with(job: OrderConfirmationJob) do
      post checkout_path, params: { order: valid_order_params }
    end
  end

  test "unknown order reference returns 404" do
    get order_path("SMK-XXXXXX")
    assert_response :not_found
  end
end
