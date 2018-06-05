class UpdateColumnActualPriceToSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :actual_price, :float, precision: 5, scale: 2
  end

  def down
    change_column :submissions, :actual_price, :float
  end
end
