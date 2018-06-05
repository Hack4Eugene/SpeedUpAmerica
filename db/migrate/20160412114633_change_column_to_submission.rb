class ChangeColumnToSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :provider_price, :decimal, precision: 5, scale: 2
  end

  def down
    change_column :submissions, :provider_price, :float
  end
end
