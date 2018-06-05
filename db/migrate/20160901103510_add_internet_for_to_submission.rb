class AddInternetForToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :internet_for, :string, limit: 20
  end
end
