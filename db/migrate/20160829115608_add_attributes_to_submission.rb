class AddAttributesToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :additional_comments, :text
    add_column :submissions, :service_plan, :string
    add_column :submissions, :internet_location, :string
    add_column :submissions, :indoor, :boolean, default: true
  end
end
