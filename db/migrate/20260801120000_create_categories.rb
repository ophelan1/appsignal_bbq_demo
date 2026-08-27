class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :tagline
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true
  end
end
