class AddShortNameToServiceProviders < ActiveRecord::Migration
  def change
    add_column :service_providers, :short_name, :string
  end
end
