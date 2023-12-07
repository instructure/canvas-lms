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

class AddColumnsToAssignmentOverrides < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_reference :assignment_overrides,
                  :wiki_page,
                  if_not_exists: true,
                  foreign_key: true,
                  index: { algorithm: :concurrently, where: "wiki_page_id IS NOT NULL", if_not_exists: true }
    add_index :assignment_overrides,
              %i[wiki_page_id set_id set_type],
              where: "wiki_page_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_overrides_on_wiki_page_id_and_set"

    add_reference :assignment_overrides,
                  :discussion_topic,
                  if_not_exists: true,
                  foreign_key: true,
                  index: { algorithm: :concurrently, where: "discussion_topic_id IS NOT NULL", if_not_exists: true }
    add_index :assignment_overrides,
              %i[discussion_topic_id set_id set_type],
              where: "discussion_topic_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_overrides_on_discussion_topic_id_and_set"

    add_reference :assignment_overrides,
                  :attachment,
                  if_not_exists: true,
                  foreign_key: true,
                  index: { algorithm: :concurrently, where: "attachment_id IS NOT NULL", if_not_exists: true }
    add_index :assignment_overrides,
              %i[attachment_id set_id set_type],
              where: "attachment_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_overrides_on_attachment_id_and_set"
  end
end
