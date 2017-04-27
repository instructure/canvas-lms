#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class DropHasColumnsFromContextExternalTools < ActiveRecord::Migration[4.2]
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
      if index_exists?(:context_external_tools, :"external_tools_#{type}")
        remove_index :context_external_tools, :"external_tools_#{type}"
      end
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
