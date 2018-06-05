class CreateProviderStatistics < ActiveRecord::Migration
  def change
    create_table :provider_statistics do |t|
      t.string :name, null: false, limit: 50
      t.integer :applications, null: false, default: 0
      t.float :rating, null: false, default: 0
      t.decimal :advertised_to_actual_ratio, null: false, precision: 5, scale: 2, default: 0
      t.decimal :average_price, null: false, precision: 5, scale: 2, default: 0
      t.string :provider_type, null: false, limit: 20, default: 'both'

      t.timestamps null: false
    end
  end
end
