class Review < ApplicationRecord
  belongs_to :product

  validates :author_name, presence: true
  validates :rating, numericality: { in: 1..5, only_integer: true }
end
