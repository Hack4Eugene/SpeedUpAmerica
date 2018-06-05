class RemoveAttributesFromSubmission < ActiveRecord::Migration
  def up
    remove_column :submissions, :census_code
    remove_column :submissions, :internet_for
    remove_column :submissions, :indoor
    remove_column :submissions, :service_plan
    remove_column :submissions, :additional_comments
  end

  def down
  end
end
