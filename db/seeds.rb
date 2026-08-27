# Sample data for the Smokestack BBQ demo store.
#
#   bin/rails db:seed
#
# Safe to re-run: it clears and rebuilds everything. Deterministic, so the
# store looks the same every time you demo it.

require "json"

DATA_DIR = Rails.root.join("db", "seed_data")

catalogue = JSON.parse(File.read(DATA_DIR.join("products.json")))
copy      = JSON.parse(File.read(DATA_DIR.join("reviews.json")))

random = Random.new(20_260_824) # fixed seed => same data every run

puts "Clearing existing data..."
OrderItem.delete_all
Order.delete_all
Review.delete_all
Product.delete_all
Category.delete_all

puts "Creating categories..."
categories = catalogue.fetch("categories").each_with_index.to_h do |attrs, index|
  category = Category.create!(
    slug: attrs.fetch("slug"),
    name: attrs.fetch("name"),
    tagline: attrs["tagline"],
    position: index
  )
  [category.slug, category]
end
puts "  #{categories.size} categories"

puts "Creating products..."
products = catalogue.fetch("products").map do |attrs|
  Product.create!(
    category: categories.fetch(attrs.fetch("category")),
    slug: attrs.fetch("id"),
    name: attrs.fetch("name"),
    price_cents: Integer(attrs.fetch("price_cents")),
    stock: Integer(attrs.fetch("stock")),
    heat: Integer(attrs.fetch("heat", 0)),
    badges: Array(attrs["badges"]).join(","),
    summary: attrs["summary"],
    description: attrs["description"]
  )
end
puts "  #{products.size} products"

puts "Creating reviews..."
authors  = copy.fetch("authors")
review_count = 0

products.each do |product|
  # Between 2 and 6 reviews each, weighted positive — but not uniformly, so
  # the ratings on the storefront look like real ones.
  count = random.rand(2..6)
  chosen_authors = authors.sample(count, random: random)

  chosen_authors.each do |author|
    roll = random.rand(100)
    bucket, rating =
      if roll < 68 then [copy.fetch("positive"), random.rand(4..5)]
      elsif roll < 90 then [copy.fetch("mixed"), 3]
      else [copy.fetch("critical"), random.rand(2..3)]
      end

    Review.create!(
      product: product,
      author_name: author,
      rating: rating,
      body: bucket.sample(random: random),
      created_at: random.rand(1..240).days.ago
    )
    review_count += 1
  end
end
puts "  #{review_count} reviews"

puts "Creating past orders..."
first_names = %w[Owen Marijke Tom Sanne Ravi Elena Cormac Yuki Pieter Nadia Gareth Ana Lukas Fiona Omar]
last_names  = %w[Phelan Vermeer Ellison Bakker Menon Fischer Byrne Tanaka Janssen Haddad Lloyd Ferreira Novak Doyle Aziz]
cities = [
  ["Amsterdam", "1015 CJ", "Netherlands"],
  ["Rotterdam", "3011 AA", "Netherlands"],
  ["Utrecht",   "3511 LX", "Netherlands"],
  ["Antwerp",   "2000",    "Belgium"],
  ["Ghent",     "9000",    "Belgium"],
  ["Berlin",    "10115",   "Germany"],
  ["Hamburg",   "20095",   "Germany"],
  ["Lyon",      "69001",   "France"],
  ["Dublin",    "D02 XY45", "Ireland"],
  ["Bristol",   "BS1 4DJ", "United Kingdom"]
]

order_count = 0
24.times do
  first = first_names.sample(random: random)
  last  = last_names.sample(random: random)
  city, postcode, country = cities.sample(random: random)

  order = Order.new(
    customer_name: "#{first} #{last}",
    email: "#{first.downcase}.#{last.downcase}@example.com",
    address: "#{random.rand(1..180)} #{%w[Keizersgracht Herengracht Lange\ Straat Hoofdweg Marktplein].sample(random: random)}",
    postcode: postcode,
    city: city,
    country: country,
    status: %w[placed shipped delivered delivered].sample(random: random),
    created_at: random.rand(1..45).days.ago
  )

  random.rand(1..4).times do
    product = products.sample(random: random)
    next if order.order_items.any? { |item| item.product_id == product.id }

    order.order_items.build(
      product: product,
      quantity: random.rand(1..3),
      unit_cents: product.price_cents
    )
  end

  next if order.order_items.empty?

  order.recalculate_totals!
  order.save!
  order_count += 1
end
puts "  #{order_count} orders"

puts
puts "Done."
puts "  #{Category.count} categories, #{Product.count} products, #{Review.count} reviews, #{Order.count} orders"
puts "  Store total value: #{Product.sum('price_cents * stock') / 100} EUR of stock"
