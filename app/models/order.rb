class Order < ApplicationRecord
  FREE_SHIPPING_THRESHOLD_CENTS = 7_500
  SHIPPING_CENTS                = 595
  VAT_RATE                      = 0.21 # prices are VAT-inclusive

  COUNTRIES = ["Netherlands", "Belgium", "Germany", "France", "Ireland", "United Kingdom"].freeze

  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  validates :reference, presence: true, uniqueness: true
  validates :customer_name, presence: true, length: { minimum: 2 }
  validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s.]+(\.[^@\s.]+)+\z/, message: "does not look right" }
  validates :address, :postcode, :city, presence: true
  validates :country, presence: true, inclusion: { in: COUNTRIES, message: "is not somewhere we ship yet" }

  before_validation :assign_reference, on: :create

  def to_param = reference

  def item_count = order_items.sum(&:quantity)

  def self.generate_reference
    "SMK-#{SecureRandom.hex(3).upcase}"
  end

  # Totals are always derived from the line items, never trusted from input.
  def recalculate_totals!
    subtotal = order_items.sum { |item| item.unit_cents * item.quantity }
    shipping = subtotal.zero? || subtotal >= FREE_SHIPPING_THRESHOLD_CENTS ? 0 : SHIPPING_CENTS
    total    = subtotal + shipping

    assign_attributes(
      subtotal_cents: subtotal,
      shipping_cents: shipping,
      total_cents: total,
      vat_cents: (total * VAT_RATE / (1 + VAT_RATE)).round
    )
  end

  private

  def assign_reference
    self.reference ||= self.class.generate_reference
  end
end
