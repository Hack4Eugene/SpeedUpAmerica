class AddColumnPingToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :ping, :integer
  end
end
