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
class AddSendMessageToAccountNotifications < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    if Shard.current.default? && !::Rails.env.test?
      Canvas::MessageHelper.create_notification({
        name: 'Account Notification',
        delay_for: 0,
        category: 'Account Notification'
      })
    end

    add_column :account_notifications, :send_message, :boolean
    change_column_default(:account_notifications, :send_message, false)
    DataFixup::BackfillNulls.run(AccountNotification, :send_message, default_value: false)
    change_column_null(:account_notifications, :send_message, false)

    add_column :account_notifications, :messages_sent_at, :datetime
  end

  def down
    remove_column :account_notifications, :send_message
    remove_column :account_notifications, :messages_sent_at

    if Shard.current.default?
      Notification.where(name: 'Account Notification').delete_all
    end
  end
end
