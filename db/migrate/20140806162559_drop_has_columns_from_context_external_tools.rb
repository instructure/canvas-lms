class DropHasColumnsFromContextExternalTools < ActiveRecord::Migration
  tag :postdeploy

  EXTENSION_TYPES = [:account_navigation, :course_home_sub_navigation, :course_navigation,
                     :course_settings_sub_navigation, :editor_button, :homework_submission,
                     :migration_selection, :resource_selection, :user_navigation]

  def up
    if connection.adapter_name == 'PostgreSQL'
      EXTENSION_TYPES.each do |type|
        drop_trigger("tool_after_insert_#{type}_is_true__tr", "context_external_tools", :generated => true)
        drop_trigger("tool_after_update_#{type}_is_true__tr", "context_external_tools", :generated => true)
        drop_trigger("tool_after_update_#{type}_is_false__tr", "context_external_tools", :generated => true)
      end
    end

    EXTENSION_TYPES.each do |type|
      remove_column :context_external_tools, :"has_#{type}"
    end

    EXTENSION_TYPES.each do |type|
      next if type == :homework_submission # note, there is no index for homework_submission
      remove_index :context_external_tools, :"external_tools_#{type}"
    end
  end

  def down
    EXTENSION_TYPES.each do |type|
      add_column :context_external_tools, :"has_#{type}", :boolean
    end

    EXTENSION_TYPES.each do |type|
      next if type == :homework_submission
      add_index :context_external_tools, [:context_id, :context_type, :"has_#{type}"], :name => "external_tools_#{type}"
    end
  end
end
