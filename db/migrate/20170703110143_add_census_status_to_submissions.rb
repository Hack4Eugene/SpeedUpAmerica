class AddCensusStatusToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :census_status, :string, limit: 10
    add_index :submissions, :census_status
  end
end
