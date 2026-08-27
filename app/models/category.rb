class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, -> { order(:position, :name) }

  def to_param = slug
end
