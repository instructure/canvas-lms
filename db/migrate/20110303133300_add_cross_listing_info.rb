class AddCrossListingInfo < ActiveRecord::Migration
  def self.up
    add_column :course_sections, :account_id, :integer, :limit => 8
  end

  def self.down
    remove_column :course_sections, :account_id
  end
end


