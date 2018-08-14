class AllowNullAttributesInSubmissions < ActiveRecord::Migration
  def up
    change_column :submissions, :testing_for, :string, null: true
    change_column :submissions, :actual_down_speed, :float, null: true
    change_column :submissions, :actual_upload_speed, :float, null: true
  end

  def down
    change_column :submissions, :testing_for, :string, null: false
    change_column :submissions, :actual_down_speed, :float, null: false
    change_column :submissions, :actual_upload_speed, :float, null: false
  end
end
