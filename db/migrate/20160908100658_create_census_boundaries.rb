class CreateCensusBoundaries < ActiveRecord::Migration
  def change
    create_table :census_boundaries do |t|
      t.string :name
      t.integer :area_identifier
      t.text :bounds, limit: 4294967295
      t.string :geo_id

      t.timestamps null: false
    end
  end
end
