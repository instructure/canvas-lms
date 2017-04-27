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

class CreatePollingTables < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :polling_polls do |t|
      t.string :title
      t.string :description

      t.integer :course_id, limit: 8, null: false

      t.timestamps null: true
    end

    create_table :polling_poll_submissions do |t|
      t.integer :poll_id, limit: 8, null: false
      t.integer :poll_choice_id, limit: 8, null: false
      t.integer :user_id, limit: 8, null: false

      t.timestamps null: true
    end

    create_table :polling_poll_choices do |t|
      t.string :text
      t.boolean :is_correct, null: false

      t.integer :poll_id, limit: 8, null: false

      t.timestamps null: true
    end

    add_index :polling_polls, :course_id
    add_index :polling_poll_submissions, :poll_choice_id
    add_index :polling_poll_submissions, :user_id
    add_index :polling_poll_submissions, [:poll_id, :user_id], unique: true
    add_index :polling_poll_choices, :poll_id

    add_foreign_key :polling_polls, :courses
    add_foreign_key :polling_poll_submissions, :users
    add_foreign_key :polling_poll_submissions, :polling_polls, column: :poll_id
    add_foreign_key :polling_poll_submissions, :polling_poll_choices, column: :poll_choice_id
    add_foreign_key :polling_poll_choices, :polling_polls, column: :poll_id
  end

  def self.down
    drop_table :polling_poll_choices
    drop_table :polling_poll_submissions
    drop_table :polling_polls
  end
end
