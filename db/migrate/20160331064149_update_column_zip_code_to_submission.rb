class UpdateColumnZipCodeToSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :zip_code, :string, limit: 10
  end

  def down
    change_column :submissions, :zip_code, :integer
  end
end
