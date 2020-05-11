#
# Copyright (C) 2020 - present Instructure, Inc.
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

class ChangeDelayedMessageIndexToIgnoreNullValues < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :delayed_messages, :notification_policy_override_id,
              algorithm: :concurrently,
              name: 'index_delayed_messages_with_notification_policy_override_id',
              where: "notification_policy_override_id IS NOT NULL"

    if index_name_exists?(:delayed_messages, 'index_delayed_messages_on_notification_policy_override_id')
      remove_index :delayed_messages, :notification_policy_override_id
    end
  end
end
