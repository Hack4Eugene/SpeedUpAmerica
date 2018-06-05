class AddIndicesOnAttributesInSubmission < ActiveRecord::Migration
  def change
    add_index :submissions, :testing_for
    add_index :submissions, :actual_down_speed
    add_index :submissions, :provider
    add_index :submissions, :rating
    add_index :submissions, :zip_code
  end
end
