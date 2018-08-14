class RemoveLimitFromIpAddressToSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :ip_address, :string, limit: 60
  end

  def down
    change_column :submissions, :ip_address, :string, limit: 30
  end
end
