# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class CreateEstimatedDuration < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    create_table :estimated_durations do |t|
      t.interval :duration
      t.references :discussion_topic, foreign_key: true, index: { where: "discussion_topic_id IS NOT NULL", unique: true }
      t.references :assignment, foreign_key: true, index: { where: "assignment_id IS NOT NULL", unique: true }
      t.references :attachment, foreign_key: true, index: { where: "attachment_id IS NOT NULL", unique: true }
      t.references :quiz, foreign_key: true, index: { where: "quiz_id IS NOT NULL", unique: true }
      t.references :wiki_page, foreign_key: true, index: { where: "wiki_page_id IS NOT NULL", unique: true }
      t.references :content_tag, foreign_key: true, index: { where: "content_tag_id IS NOT NULL", unique: true }
      t.references :root_account, foreign_key: { to_table: :accounts }, index: false, null: false
      t.timestamps
      t.replica_identity_index
      # Add a check constraint to enforce exactly one reference is present
      t.check_constraint <<~SQL.squish, name: "check_that_exactly_one_foreign_key_is_present"
        (
          (discussion_topic_id IS NOT NULL)::int +
          (assignment_id IS NOT NULL)::int +
          (attachment_id IS NOT NULL)::int +
          (quiz_id IS NOT NULL)::int +
          (wiki_page_id IS NOT NULL)::int +
          (content_tag_id IS NOT NULL)::int
        ) = 1
      SQL
    end
  end
end
