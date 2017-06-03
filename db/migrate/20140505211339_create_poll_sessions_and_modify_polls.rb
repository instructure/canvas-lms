#
# Copyright (C) 2014 - present Instructure, Inc.
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

class CreatePollSessionsAndModifyPolls < ActiveRecord::Migration[4.2]
  tag :predeploy

  # rubocop:disable Migration/RemoveColumn
  def self.up
    create_table :polling_poll_sessions do |t|
      t.boolean :is_published, null: false, default: false
      t.boolean :has_public_results, null: false, default: false

      t.integer :course_id, limit: 8, null: false
      t.integer :course_section_id, limit: 8
      t.integer :poll_id, limit: 8, null: false

      t.timestamps null: true
    end
    add_column :polling_poll_submissions, :poll_session_id, :integer, limit: 8

    # Polls will be scoped to user as opposed to course.
    # PollSessions scope to course/course_section
    remove_foreign_key :polling_polls, :courses
    remove_column :polling_polls, :course_id
    add_column :polling_polls, :user_id, :integer, limit: 8

    # Get around NOT NULL with no default value constraints
    change_column_null :polling_poll_submissions, :poll_session_id, false
    change_column_null :polling_polls, :user_id, false

    # Requested changes from mobile
    change_column :polling_poll_choices, :is_correct, :boolean, default: false
    rename_column :polling_polls, :title, :question

    remove_index :polling_poll_submissions, [:poll_id, :user_id]

    add_index :polling_poll_sessions, :course_id
    add_index :polling_poll_sessions, :course_section_id
    add_index :polling_poll_sessions, :poll_id
    add_index :polling_poll_submissions, :poll_session_id
    add_index :polling_polls, :user_id

    add_foreign_key :polling_poll_sessions, :courses
    add_foreign_key :polling_poll_sessions, :course_sections
    add_foreign_key :polling_poll_sessions, :polling_polls, column: :poll_id
    add_foreign_key :polling_poll_submissions, :polling_poll_sessions, column: :poll_session_id
    add_foreign_key :polling_polls, :users
  end

  def self.down
    rename_column :polling_polls, :question, :title

    remove_column :polling_polls, :user_id
    add_column :polling_polls, :course_id, :integer, limit: 8, null: false
    add_foreign_key :polling_polls, :courses

    remove_column :polling_poll_submissions, :poll_session_id
    drop_table :polling_poll_sessions
  end
end
