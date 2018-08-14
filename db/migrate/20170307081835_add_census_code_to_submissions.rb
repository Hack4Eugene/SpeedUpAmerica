class AddCensusCodeToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :census_code, :integer
  end
end
