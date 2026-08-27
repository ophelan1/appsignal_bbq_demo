class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.string  :author_name, null: false
      t.integer :rating, null: false
      t.text    :body

      t.timestamps
    end
  end
end
