require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup { build_catalogue! }

  test "badge helpers read the comma separated list" do
    assert_predicate @rub, :bestseller?
    refute_predicate @rub, :new?
    refute_predicate @rub, :flagship?
  end

  test "stock helpers" do
    assert_predicate @rub, :in_stock?
    refute_predicate @rub, :low_stock?
    assert_predicate @scarce, :low_stock?
    refute_predicate @sold_out, :in_stock?
  end

  test "max orderable is bounded by stock and the per line cap" do
    assert_equal 3, @scarce.max_orderable
    assert_equal Product::MAX_PER_LINE, @rub.max_orderable
    assert_equal 0, @sold_out.max_orderable
  end

  test "average rating is nil without reviews and rounded with them" do
    assert_nil @rub.average_rating
    @rub.reviews.create!(author_name: "A", rating: 5, body: "Great")
    @rub.reviews.create!(author_name: "B", rating: 4, body: "Good")
    assert_equal 4.5, @rub.reload.average_rating
  end

  test "slug is the url parameter" do
    assert_equal "rub-brisket", @rub.to_param
  end
end
