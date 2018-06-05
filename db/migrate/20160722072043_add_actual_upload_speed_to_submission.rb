class AddActualUploadSpeedToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :actual_upload_speed, :float, null: false
  end
end
