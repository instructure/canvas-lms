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

class CreateQuizSubmissionEvents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    create_table :quiz_submission_events do |t|
      t.integer :attempt
      t.string :event_type
      t.integer :quiz_submission_id, limit: 8, null: false
      t.text :answers
      t.datetime :created_at
    end

    # for sorting:
    add_index :quiz_submission_events, :created_at

    # for locating predecessor events:
    add_index :quiz_submission_events, [ :quiz_submission_id, :attempt, :created_at ],
      name: 'event_predecessor_locator_index'

    add_foreign_key :quiz_submission_events, :quiz_submissions
  end

  def down
    drop_table :quiz_submission_events
  end
end
