class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string  :reference, null: false
      t.string  :customer_name, null: false
      t.string  :email, null: false
      t.string  :address
      t.string  :postcode
      t.string  :city
      t.string  :country
      t.text    :notes
      t.integer :subtotal_cents, default: 0, null: false
      t.integer :shipping_cents, default: 0, null: false
      t.integer :vat_cents, default: 0, null: false
      t.integer :total_cents, default: 0, null: false
      t.string  :status, default: "placed", null: false

      t.timestamps
    end

    add_index :orders, :reference, unique: true
  end
end
