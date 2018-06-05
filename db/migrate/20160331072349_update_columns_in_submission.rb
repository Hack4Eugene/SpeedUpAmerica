class UpdateColumnsInSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :address, :string, null: true
    change_column :submissions, :latitude, :string, null: true
    change_column :submissions, :longitude, :float, null: true
  end

  def down
    change_column :submissions, :address, :string, null: false
    change_column :submissions, :latitude, :string, null: false
    change_column :submissions, :longitude, :float, null: false
  end
end
