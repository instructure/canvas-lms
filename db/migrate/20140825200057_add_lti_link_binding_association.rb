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

class AddLtiLinkBindingAssociation < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    drop_table :lti_tool_links
    drop_table :lti_tool_settings

    add_column :lti_tool_proxy_bindings, :enabled, :boolean, null: false, default: true

    create_table :lti_tool_settings do |t|
      t.integer :tool_proxy_id, limit:8, null: false
      t.integer :context_id, limit: 8
      t.string :context_type
      t.text :resource_link_id
      t.text :custom
      t.timestamps null: true
    end

    add_index :lti_tool_settings, [:resource_link_id, :context_type, :context_id, :tool_proxy_id],name: 'index_lti_tool_settings_on_link_context_and_tool_proxy', unique: true

  end

  def self.down
    remove_column :lti_tool_proxy_bindings, :enabled
    drop_table :lti_tool_settings
    create_table :lti_tool_settings do |t|
      t.integer :settable_id, limit: 8, null: false
      t.string :settable_type, null: false
      t.text :custom
    end

    create_table :lti_tool_links do |t|
      t.integer :resource_handler_id, limit: 8, null: false
      t.string :uuid, null: false
    end


    add_index :lti_tool_settings, [:settable_id, :settable_type], unique: true
    add_index :lti_tool_links, :uuid, unique: true
  end

end
