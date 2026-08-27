class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_cents, numericality: { greater_than: 0, only_integer: true }

  def line_total_cents = unit_cents * quantity
end
