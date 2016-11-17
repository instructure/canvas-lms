class CreateContextExternalToolAssignmentLookups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :context_external_tool_assignment_lookups do |t|
      t.integer :assignment_id, limit: 8, null: false
      t.integer :context_external_tool_id, limit: 8, null: false
    end

    add_foreign_key :context_external_tool_assignment_lookups, :assignments
    add_foreign_key :context_external_tool_assignment_lookups, :context_external_tools

    add_index :context_external_tool_assignment_lookups, [:context_external_tool_id, :assignment_id], unique: true, name: 'tool_to_assign'
    add_index :context_external_tool_assignment_lookups, :assignment_id
  end
end
