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

    # create some triggers so nothing falls through the cracks
    if connection.adapter_name == 'PostgreSQL'

      EXTENSION_TYPES.each do |type|
        column = "has_#{type}"
        create_trigger("tool_after_insert_#{type}_is_true__tr", :generated => true).
            on("context_external_tools").
            after(:insert).
            where("NEW.#{column}") do
          <<-SQL_ACTIONS
            INSERT INTO context_external_tool_placements(placement_type, context_external_tool_id)
            VALUES ('#{type}', NEW.id)
          SQL_ACTIONS
        end
        connection.set_search_path_on_function("tool_after_insert_#{type}_is_true__tr")

        create_trigger("tool_after_update_#{type}_is_true__tr", :generated => true).
            on("context_external_tools").
            after(:update).
            where("NEW.#{column}") do
          <<-SQL_ACTIONS
            INSERT INTO context_external_tool_placements(placement_type, context_external_tool_id)
            SELECT '#{type}', NEW.id
            WHERE NOT EXISTS(
              SELECT 1 FROM context_external_tool_placements WHERE placement_type = '#{type}' AND context_external_tool_id = NEW.id
            )
          SQL_ACTIONS
        end
        connection.set_search_path_on_function("tool_after_update_#{type}_is_true__tr")


        create_trigger("tool_after_update_#{type}_is_false__tr", :generated => true).
            on("context_external_tools").
            after(:update).
            where("NOT NEW.#{column}") do
          <<-SQL_ACTIONS
            DELETE FROM context_external_tool_placements WHERE placement_type = '#{type}' AND context_external_tool_id = NEW.id
          SQL_ACTIONS
        end
        connection.set_search_path_on_function("tool_after_update_#{type}_is_false__tr")
      end
    end

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
