#
# Copyright (C) 2011 - present Instructure, Inc.
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

class AddMissingTooLongIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.add_index_with_check(table_name, column_name, options)
    return if index_exists?(table_name.to_s, column_name, :name => options[:name].to_s)
    add_index(table_name, column_name, options)
  end

  def self.up
    # some indexes failed to create with a logged warning because the auto-generated names were too long.
    # this fixes them up, and we added code in
    # config/initializers/active_record.rb to raise an exception, rather than
    # just log a warning, if another too-long index crops up in the future.
    #
    # we go through add_index_with_check, because we fixed the original
    # migrations and because some adapters don't enforce the same index length,
    # so they may have created some/all of these already.
    add_index_with_check :custom_fields, %w(scoper_type scoper_id target_type name), :name => "custom_field_lookup"
    add_index_with_check :learning_outcome_results, [:user_id, :content_tag_id, :associated_asset_id, :associated_asset_type], :name => "index_learning_outcome_results_association"
    add_index_with_check :context_external_tools, [:context_id, :context_type, :has_user_navigation], :name => "external_tools_user_navigation"
    add_index_with_check :context_external_tools, [:context_id, :context_type, :has_course_navigation], :name => "external_tools_course_navigation"
    add_index_with_check :context_external_tools, [:context_id, :context_type, :has_account_navigation], :name => "external_tools_account_navigation"
    add_index_with_check :context_external_tools, [:context_id, :context_type, :has_resource_selection], :name => "external_tools_resource_selection"
    add_index_with_check :context_external_tools, [:context_id, :context_type, :has_editor_button], :name => "external_tools_editor_button"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
