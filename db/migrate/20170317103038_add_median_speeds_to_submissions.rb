class AddMedianSpeedsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :upload_median, :float
    add_column :submissions, :download_median, :float
  end
end
