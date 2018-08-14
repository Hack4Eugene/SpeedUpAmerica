class AddFromMLabToProviderStatistics < ActiveRecord::Migration
  def change
    add_column :provider_statistics, :from_mlab, :boolean, default: false
  end
end
