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
#

class CreateNotificationPolicyOverrides < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :notification_policy_overrides do |t|
      t.belongs_to :context, polymorphic: { default: 'Course' },
                   limit: 8, null: false, index: { name: 'index_notification_policy_overrides_on_context' }
      t.belongs_to :communication_channel, null: false, foreign_key: true
      t.belongs_to :notification, foreign_key: true, index: true
      t.string :workflow_state, default: 'active', null: false, index: true
      t.string :frequency
      t.timestamps
    end

    add_index :notification_policy_overrides, %i(communication_channel_id notification_id),
              name: 'index_notification_policies_overrides_on_cc_id_and_notification'
    add_index :notification_policy_overrides, %i(context_id context_type communication_channel_id notification_id),
              where: 'notification_id IS NOT NULL',
              unique: true, name: 'index_notification_policies_overrides_uniq_context_notification'
    add_index :notification_policy_overrides, %i(context_id context_type communication_channel_id),
              where: 'notification_id IS NULL',
              unique: true, name: 'index_notification_policies_overrides_uniq_context_and_cc'
  end
end
