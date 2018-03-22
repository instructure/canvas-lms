#
# Copyright (C) 2018 - present Instructure, Inc.
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

class AddWorkflowStatesToTokensAndEndpoints < ActiveRecord::Migration[5.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :access_tokens, :workflow_state, :string
    change_column_default(:access_tokens, :workflow_state, 'active')
    DataFixup::BackfillNulls.run(AccessToken, :workflow_state, default_value: 'active')
    change_column_null(:access_tokens, :workflow_state, false)
    add_index :access_tokens, :workflow_state, algorithm: :concurrently

    add_column :notification_endpoints, :workflow_state, :string
    change_column_default(:notification_endpoints, :workflow_state, 'active')
    DataFixup::BackfillNulls.run(NotificationEndpoint, :workflow_state, default_value: 'active')
    change_column_null(:notification_endpoints, :workflow_state, false)
    add_index :notification_endpoints, :workflow_state, algorithm: :concurrently
  end

  def down
    remove_column :access_tokens, :workflow_state
    remove_column :notification_endpoints, :workflow_state
  end
end
