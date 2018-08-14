class UpdateActualUploadSpeedInSubmissions < ActiveRecord::Migration
  def up
    change_column :submissions, :actual_upload_speed, :float, default: 0.0
  end

  def down
    change_column :submissions, :actual_upload_speed, :float, default: nil
  end
end
