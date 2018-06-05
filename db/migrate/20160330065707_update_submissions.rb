class UpdateSubmissions < ActiveRecord::Migration
  def up
    change_column :submissions, :provider, :string, null: true
    change_column :submissions, :connected_with, :string, null: true
    change_column :submissions, :monthly_price, :float, null: true
    change_column :submissions, :provider_down_speed, :float, null: true
    change_column :submissions, :provider_price, :float, null: true
    change_column :submissions, :actual_price, :float, null: true
    change_column :submissions, :rating, :integer, null: true
  end

  def down
    change_column :submissions, :provider, :string, null: false
    change_column :submissions, :connected_with, :string, null: false
    change_column :submissions, :monthly_price, :float, null: false
    change_column :submissions, :provider_down_speed, :float, null: false
    change_column :submissions, :provider_price, :float, null: false
    change_column :submissions, :actual_price, :float, null: false
    change_column :submissions, :rating, :integer, null: false
  end
end
