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

class AddForeignKeys8 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :account_notifications, :users, delay_validation: true
    add_foreign_key_if_not_exists :account_reports, :users, delay_validation: true
    add_foreign_key_if_not_exists :account_users, :users, delay_validation: true
    add_foreign_key_if_not_exists :assessment_requests, :users, column: :assessor_id, delay_validation: true
    add_foreign_key_if_not_exists :assessment_requests, :users, delay_validation: true
    add_foreign_key_if_not_exists :calendar_events, :users, delay_validation: true
    add_foreign_key_if_not_exists :collaborators, :users, delay_validation: true
    add_foreign_key_if_not_exists :content_exports, :users, delay_validation: true
    add_foreign_key_if_not_exists :content_migrations, :users, delay_validation: true
    add_foreign_key_if_not_exists :context_module_progressions, :users, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entries, :users, column: :editor_id, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entries, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :account_notifications, :users
    remove_foreign_key_if_exists :account_reports, :users
    remove_foreign_key_if_exists :account_users, :users
    remove_foreign_key_if_exists :assessment_requests, column: :assessor_id
    remove_foreign_key_if_exists :assessment_requests, :users
    remove_foreign_key_if_exists :calendar_events, :users
    remove_foreign_key_if_exists :collaborators, :users
    remove_foreign_key_if_exists :content_exports, :users
    remove_foreign_key_if_exists :content_migrations, :users
    remove_foreign_key_if_exists :context_module_progressions, :users
    remove_foreign_key_if_exists :discussion_entries, column: :editor_id
    remove_foreign_key_if_exists :discussion_entries, :users
  end
end
