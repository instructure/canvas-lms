class AddGroupIdToCollaborators < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :collaborators, :group_id, :integer, :limit => 8
    add_index  :collaborators, [:group_id], :name => 'index_collaborators_on_group_id'
  end

  def self.down
    remove_column :collaborators, :group_id
  end
end
