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

class AddForeignKeys1 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :abstract_courses, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :abstract_courses, :enrollment_terms, :delay_validation => true
    add_foreign_key_if_not_exists :abstract_courses, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :access_tokens, :users, :delay_validation => true
    add_foreign_key_if_not_exists :account_authorization_configs, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_notifications, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_reports, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_reports, :attachments, :delay_validation => true
    add_foreign_key_if_not_exists :account_users, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :accounts, :accounts, :column => :parent_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :accounts, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :alert_criteria, :alerts, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :abstract_courses, :accounts
    remove_foreign_key_if_exists :abstract_courses, :enrollment_terms
    remove_foreign_key_if_exists :abstract_courses, :accounts, :column => :root_account_id
    remove_foreign_key_if_exists :access_tokens, :users
    remove_foreign_key_if_exists :account_authorization_configs, :accounts
    remove_foreign_key_if_exists :account_notifications, :accounts
    remove_foreign_key_if_exists :account_reports, :accounts
    remove_foreign_key_if_exists :account_reports, :attachments
    remove_foreign_key_if_exists :account_users, :accounts
    remove_foreign_key_if_exists :accounts, :accounts, :column => :parent_account_id
    remove_foreign_key_if_exists :accounts, :accounts, :column => :root_account_id
    remove_foreign_key_if_exists :alert_criteria, :alerts
  end
end
