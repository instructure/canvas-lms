class AddGroupLeaderIdToGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :groups, :leader_id, :integer, :limit => 8
    add_foreign_key :groups, :users, column: :leader_id
  end

  def self.down
    remove_foreign_key :groups, column: :leader_id
    remove_column :groups, :leader_id
  end
end
