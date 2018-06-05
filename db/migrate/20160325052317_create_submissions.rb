class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.string :testing_for, limit: 20, null: false
      t.string :address, limit: 100, null: false
      t.integer :zip_code
      t.string :provider, limit: 50, null: false
      t.string :connected_with, limit: 50, null: false
      t.float :monthly_price, null: false
      t.float :provider_down_speed, null: false
      t.float :provider_price, null: false
      t.float :actual_down_speed, null: false
      t.float :actual_price, null: false
      t.integer :rating, null: false
      t.boolean :completed, default: false

      t.timestamps null: false
    end
  end
end
