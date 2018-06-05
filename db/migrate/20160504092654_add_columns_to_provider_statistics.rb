class AddColumnsToProviderStatistics < ActiveRecord::Migration
  def change
    add_column :provider_statistics, :actual_speed_sum, :decimal, precision: 60, scale: 2, null: false, default: 0
    add_column :provider_statistics, :provider_speed_sum, :decimal, precision: 60, scale: 2, null: false, default: 0
  end
end
