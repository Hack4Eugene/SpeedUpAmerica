class CreateServiceProviders < ActiveRecord::Migration
  def change
    create_table :service_providers do |t|
      t.integer :start_ipa
      t.integer :end_ipa
      t.string :name

      t.timestamps null: false
    end
  end
end
