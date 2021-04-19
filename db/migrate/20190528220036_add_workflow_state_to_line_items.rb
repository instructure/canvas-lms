# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#
class AddWorkflowStateToLineItems < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :lti_line_items, :workflow_state, :string, null: false, default: 'active'
    add_column :lti_results, :workflow_state, :string, null: false, default: 'active'
    add_column :lti_resource_links, :workflow_state, :string, null: false, default: 'active'

    add_index :lti_resource_links, :workflow_state, algorithm: :concurrently
    add_index :lti_results, :workflow_state, algorithm: :concurrently
    add_index :lti_line_items, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :lti_line_items, :workflow_state, :string
    remove_column :lti_results, :workflow_state, :string
    remove_column :lti_resource_links, :workflow_state, :string

    remove_index :lti_resource_links, :workflow_state
    remove_index :lti_results, :workflow_state
    remove_index :lti_line_items, :workflow_state
  end
end
