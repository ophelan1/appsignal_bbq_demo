class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string  :slug, null: false
      t.string  :name, null: false
      t.integer :price_cents, null: false
      t.integer :stock, default: 0, null: false
      t.integer :heat, default: 0, null: false
      t.string  :badges, default: "", null: false
      t.string  :summary
      t.text    :description

      t.timestamps
    end

    add_index :products, :slug, unique: true
  end
end
