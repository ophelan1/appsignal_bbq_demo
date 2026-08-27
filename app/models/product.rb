class Product < ApplicationRecord
  MAX_PER_LINE = 20

  belongs_to :category
  has_many :reviews, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price_cents, numericality: { greater_than: 0, only_integer: true }
  validates :stock, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  scope :in_stock,   -> { where(stock: 1..) }
  scope :bestsellers, -> { where("badges LIKE ?", "%bestseller%") }

  def to_param = slug

  def badge_list = badges.to_s.split(",").map(&:strip).reject(&:empty?)

  def in_stock?   = stock.positive?
  def low_stock?  = stock.positive? && stock <= 5
  def new?        = badge_list.include?("new")
  def bestseller? = badge_list.include?("bestseller")
  def flagship?   = badge_list.include?("flagship")

  # Clamped by both real stock and a per-line sanity limit.
  def max_orderable = [stock, MAX_PER_LINE].min

  def average_rating
    return nil if reviews.empty?

    (reviews.sum(&:rating).to_f / reviews.size).round(1)
  end
end
