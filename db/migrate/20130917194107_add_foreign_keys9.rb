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

class AddForeignKeys9 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :discussion_entry_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topic_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topics, :users, column: :editor_id, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topics, :users, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :users, column: :associated_user_id, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :users, delay_validation: true
    add_foreign_key_if_not_exists :external_feed_entries, :users, delay_validation: true
    add_foreign_key_if_not_exists :external_feeds, :users, delay_validation: true
    add_foreign_key_if_not_exists :grading_standards, :users, delay_validation: true
    add_foreign_key_if_not_exists :group_memberships, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :discussion_entry_participants, :users
    remove_foreign_key_if_exists :discussion_topic_participants, :users
    remove_foreign_key_if_exists :discussion_topics, column: :editor_id
    remove_foreign_key_if_exists :discussion_topics, :users
    remove_foreign_key_if_exists :enrollments, column: :associated_user_id
    remove_foreign_key_if_exists :enrollments, :users
    remove_foreign_key_if_exists :external_feed_entries, :users
    remove_foreign_key_if_exists :external_feeds, :users
    remove_foreign_key_if_exists :grading_standards, :users
    remove_foreign_key_if_exists :group_memberships, :users
  end
end
