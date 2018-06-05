class ChangeColumnTypesToSubmissions < ActiveRecord::Migration
  def up
    change_column :submissions, :provider_price, :decimal, precision: 15, scale: 2
    change_column :submissions, :actual_price, :decimal, precision: 15, scale: 2
  end

  def down
    change_column :submissions, :provider_price, :decimal, precision: 5, scale: 2
    change_column :submissions, :actual_price, :decimal, precision: 5, scale: 2
  end
end
