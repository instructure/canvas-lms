# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

class AddColumnsToAssignmentOverrideStudents < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_reference :assignment_override_students,
                  :wiki_page,
                  if_not_exists: true,
                  foreign_key: true,
                  index: false
    add_index :assignment_override_students,
              [:wiki_page_id, :user_id],
              where: "wiki_page_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true

    add_reference :assignment_override_students,
                  :discussion_topic,
                  if_not_exists: true,
                  foreign_key: true,
                  index: false
    add_index :assignment_override_students,
              [:discussion_topic_id, :user_id],
              where: "discussion_topic_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_override_students_on_discussion_topic_and_user"

    add_reference :assignment_override_students,
                  :attachment,
                  if_not_exists: true,
                  foreign_key: true,
                  index: false
    add_index :assignment_override_students,
              [:attachment_id, :user_id],
              where: "attachment_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
