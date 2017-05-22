#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AddSurveyFunctionalityToAccountNotifications < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_notifications, :required_account_service, :string
    add_column :account_notifications, :months_in_display_cycle, :int
    # this table is small enough for transactional index creation
    add_index :account_notifications, [:account_id, :end_at, :start_at], name: "index_account_notifications_by_account_and_timespan"
    remove_index :account_notifications, [:account_id, :start_at]
  end

  def self.down
    remove_column :account_notifications, :required_account_setting
    remove_column :account_notifications, :months_in_display_cycle
    add_index :account_notifications, [:account_id, :start_at]
    remove_index :account_notifications, name: "index_account_notifications_by_account_and_timespan"
  end
end
