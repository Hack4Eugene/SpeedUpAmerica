class RemoveAddressLimitInSubmission < ActiveRecord::Migration
  def change
    change_column :submissions, :address, :string, limit: 250
  end
end
