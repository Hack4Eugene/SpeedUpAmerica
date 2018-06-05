class AddColumnsToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :latitude, :float
    add_column :submissions, :longitude, :float
  end
end
