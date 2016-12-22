class CreateAssignmentConfigurationToolLookups < ActiveRecord::Migration
  tag :predeploy

  def change
    create_table :assignment_configuration_tool_lookups do |t|
      t.integer :assignment_id, limit: 8, null: false
      t.integer :tool_id, limit: 8, null: false
      t.string :tool_type, null: false
    end

    add_foreign_key :assignment_configuration_tool_lookups, :assignments

    add_index :assignment_configuration_tool_lookups, [:tool_id, :tool_type, :assignment_id], unique: true, name: 'index_tool_lookup_on_tool_assignment_id'
    add_index :assignment_configuration_tool_lookups, :assignment_id
  end
end
