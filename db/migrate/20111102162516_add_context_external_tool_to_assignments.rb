class AddContextExternalToolToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :context_external_tool_id, :integer, :limit => 8
  end

  def self.down
    remove_column :assignments, :context_external_tool_id
  end
end
