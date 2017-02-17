class CreateContextExternalToolPlacements < ActiveRecord::Migration[4.2]
  tag :predeploy

  EXTENSION_TYPES = [:account_navigation, :course_home_sub_navigation, :course_navigation,
                     :course_settings_sub_navigation, :editor_button, :homework_submission,
                     :migration_selection, :resource_selection, :user_navigation]

  def up
    create_table :context_external_tool_placements do |t|
      t.string :placement_type
      t.integer :context_external_tool_id, limit: 8, null: false
    end

    add_index :context_external_tool_placements, :context_external_tool_id, :name => 'external_tool_placements_tool_id'
    add_index :context_external_tool_placements, [:placement_type, :context_external_tool_id], unique: true, :name => 'external_tool_placements_type_and_tool_id'

    add_foreign_key :context_external_tool_placements, :context_external_tools

    # now populate the placements
    EXTENSION_TYPES.each do |type|
      column = :"has_#{type}"
      ContextExternalTool.where(column => true).find_ids_in_batches do |ids|
        opts = ids.map{|id| {:context_external_tool_id => id, :placement_type => type}}
        ActiveRecord::Base.connection.bulk_insert('context_external_tool_placements', opts)
      end
    end
  end

  def down
    EXTENSION_TYPES.each do |type|
      column = :"has_#{type}"

      # set it false if the placement is missing
      ContextExternalTool.where(column => true).find_ids_in_batches do |ids|
        untrue_ids = ids - ContextExternalToolPlacement.where(:context_external_tool_id => ids).pluck(:context_external_tool_id)
        ContextExternalTool.where(:id => untrue_ids).update_all(column => false)
      end

      # set it true if the placement is there
      ContextExternalToolPlacement.where(:placement_type => type).find_in_batches do |placements|
        ContextExternalTool.where(:id => placements.map(&:context_external_tool_id)).update_all(column => true)
      end
    end

    drop_table :context_external_tool_placements
  end
end
