class AddProviderUploadSpeedInSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :provider_upload_speed, :float
  end
end
