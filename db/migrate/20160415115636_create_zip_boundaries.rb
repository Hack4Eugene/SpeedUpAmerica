class CreateZipBoundaries < ActiveRecord::Migration
  def change
    create_table :zip_boundaries do |t|
      t.string :name
      t.string :zip_type
      t.text :bounds, limit: 4294967295

      t.timestamps null: false
    end
  end
end
