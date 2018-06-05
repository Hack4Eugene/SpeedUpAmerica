class ChangeTypeOfColumnInSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :latitude, :float
    change_column :submissions, :actual_price, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :submissions, :latitude, :string
    change_column :submissions, :actual_price, :float, precision: 5, scale: 2
  end
end
