class AddMutedToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :muted, :boolean, :default => false
    Assignment.update_all :muted => false
  end

  def self.down
    remove_column :assignments, :muted
  end
end
