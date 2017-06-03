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

class AddContextToToolProxy < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :lti_tool_proxies, name: 'index_lti_tool_proxies_on_root_account_prod_fam_and_prod_ver'
    remove_foreign_key :lti_tool_proxies, column: :root_account_id

    rename_column :lti_tool_proxies, :root_account_id, :context_id
    add_column :lti_tool_proxies, :context_type, :string, null: false, default: 'Account'
    change_column :lti_tool_proxies, :context_type, :string, null:false

  end

  def self.down

    Lti::ToolProxy.where("context_type <> 'Account'").preload(:context).each do |tp|
      tp.context_id = tp.context.root_account_id
      tp.save
    end

    rename_column :lti_tool_proxies, :context_id, :root_account_id
    remove_column :lti_tool_proxies, :context_type
    add_index :lti_tool_proxies, [:root_account_id, :product_family_id, :product_version], name: 'index_lti_tool_proxies_on_root_account_prod_fam_and_prod_ver', unique: true
    add_foreign_key :lti_tool_proxies, :accounts, column: :root_account_id

  end

end
