ENV["RAILS_ENV"] ||= "test"
ENV["APPSIGNAL_PUSH_API_KEY"] = nil # never report from the test suite

require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)

  # Small, explicit fixtures built in Ruby. Fewer surprises than YAML fixtures
  # and it keeps each test readable on its own.
  def build_catalogue!
    @category = Category.create!(slug: "rubs", name: "Rubs & Spices", tagline: "Bark starts here", position: 0)
    @tools    = Category.create!(slug: "tools", name: "Tools & Gear", tagline: "Kit that earns its keep", position: 1)

    @rub = Product.create!(
      category: @category, slug: "rub-brisket", name: "Blackened Brisket Rub",
      price_cents: 1450, stock: 140, heat: 2, badges: "bestseller",
      summary: "16-mesh pepper and coarse salt.", description: "Two ingredients do most of the work."
    )
    @scarce = Product.create!(
      category: @tools, slug: "tool-slicer", name: "30cm Brisket Slicer",
      price_cents: 6500, stock: 3, badges: "",
      summary: "Granton-edged carving knife.", description: "Long enough to cross a packer."
    )
    @sold_out = Product.create!(
      category: @tools, slug: "tool-gloves", name: "Aramid Pit Gloves",
      price_cents: 3900, stock: 0, badges: "",
      summary: "Heat-resistant gloves.", description: "Rated to 350C."
    )
  end

  def valid_order_params
    {
      customer_name: "Owen Phelan", email: "owen@appsignal.com",
      address: "Keizersgracht 1", postcode: "1015 CJ",
      city: "Amsterdam", country: "Netherlands", notes: ""
    }
  end
end
