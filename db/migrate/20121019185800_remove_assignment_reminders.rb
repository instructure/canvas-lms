#
# Copyright (C) 2012 - present Instructure, Inc.
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

class RemoveAssignmentReminders < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :assignment_reminders

    remove_column :assignments, :reminders_created_for_due_at
    remove_column :assignments, :publishing_reminder_sent
  end

  def self.down
    create_table :assignment_reminders do |t|
      t.integer  :assignment_id, :limit => 8
      t.integer  :user_id,       :limit => 8
      t.datetime :remind_at
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :reminder_type
    end
    add_index :assignment_reminders, [:assignment_id], :name => "index_assignment_reminders_on_assignment_id"
    add_index :assignment_reminders, [:user_id], :name => "index_assignment_reminders_on_user_id"

    add_column :assignments, :reminders_created_for_due_at, :datetime
    add_column :assignments, :publishing_reminder_sent, :boolean, :default => false
  end
end
