class ChangeLengthOfAveragePriceInProviderStatistics < ActiveRecord::Migration
  def up
    change_column :provider_statistics, :average_price, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :provider_statistics, :average_price, :decimal, precision: 5, scale: 2
  end
end
