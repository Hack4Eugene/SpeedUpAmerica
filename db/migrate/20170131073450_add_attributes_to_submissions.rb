class AddAttributesToSubmissions < ActiveRecord::Migration
  def change
    add_column :submissions, :test_id, :string, limit: 120
    add_column :submissions, :ip_address, :string, limit: 30
    add_column :submissions, :hostname, :string
    add_column :submissions, :from_mlab, :boolean, default: false
    add_column :submissions, :area_code, :string, limit: 15

    add_index :submissions, :test_id
  end
end
