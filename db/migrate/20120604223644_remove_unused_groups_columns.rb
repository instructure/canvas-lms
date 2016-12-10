class RemoveUnusedGroupsColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :groups, :type
    remove_column :groups, :groupable_id
    remove_column :groups, :groupable_type
  end

  def self.down
    add_column :groups, :type, :string
    add_column :groups, :groupable_id, :integer, :limit => 8
    add_column :groups, :groupable_type, :string
  end
end
