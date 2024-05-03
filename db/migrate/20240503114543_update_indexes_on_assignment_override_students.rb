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

class UpdateIndexesOnAssignmentOverrideStudents < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :assignment_override_students,
              :wiki_page_id,
              algorithm: :concurrently,
              where: "wiki_page_id IS NOT NULL",
              if_not_exists: true
    add_index :assignment_override_students,
              :discussion_topic_id,
              algorithm: :concurrently,
              where: "discussion_topic_id IS NOT NULL",
              if_not_exists: true
    add_index :assignment_override_students,
              :attachment_id,
              algorithm: :concurrently,
              where: "attachment_id IS NOT NULL",
              if_not_exists: true

    add_index :assignment_override_students,
              [:wiki_page_id, :user_id],
              unique: true,
              algorithm: :concurrently,
              where: "wiki_page_id IS NOT NULL AND workflow_state = 'active'",
              if_not_exists: true,
              name: "index_aos_on_active_wiki_page_and_user"
    add_index :assignment_override_students,
              [:discussion_topic_id, :user_id],
              unique: true,
              algorithm: :concurrently,
              where: "discussion_topic_id IS NOT NULL AND workflow_state = 'active'",
              if_not_exists: true,
              name: "index_aos_on_active_discussion_topic_and_user"
    add_index :assignment_override_students,
              [:attachment_id, :user_id],
              unique: true,
              algorithm: :concurrently,
              where: "attachment_id IS NOT NULL AND workflow_state = 'active'",
              if_not_exists: true,
              name: "index_aos_on_active_attachment_and_user"

    remove_index :assignment_override_students,
                 [:wiki_page_id, :user_id],
                 unique: true,
                 algorithm: :concurrently,
                 where: "wiki_page_id IS NOT NULL",
                 if_exists: true,
                 name: "index_assignment_override_students_on_wiki_page_id_and_user_id"
    remove_index :assignment_override_students,
                 [:discussion_topic_id, :user_id],
                 unique: true,
                 algorithm: :concurrently,
                 where: "discussion_topic_id IS NOT NULL",
                 if_exists: true,
                 name: "index_assignment_override_students_on_discussion_topic_and_user"
    remove_index :assignment_override_students,
                 [:attachment_id, :user_id],
                 unique: true,
                 algorithm: :concurrently,
                 where: "attachment_id IS NOT NULL",
                 if_exists: true,
                 name: "index_assignment_override_students_on_attachment_id_and_user_id"
  end
end
