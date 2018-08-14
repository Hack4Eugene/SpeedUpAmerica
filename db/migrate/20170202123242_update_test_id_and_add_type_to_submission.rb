class UpdateTestIdAndAddTypeToSubmission < ActiveRecord::Migration
  def up
    change_column :submissions, :test_id, :string, limit: 140
    add_column :submissions, :test_type, :string, limit: 15, default: 'both'
    add_index :submissions, :test_type
  end

  def down
    change_column :submissions, :test_id, :string, limit: 120
    remove_index :submissions, :test_type
    remove_column :submissions, :test_type
  end
end
