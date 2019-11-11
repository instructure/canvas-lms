#
# Copyright (C) 2019 - present Instructure, Inc.
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
#
class AddMiscPerformanceIndexes < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :discussion_entries, [:user_id, :discussion_topic_id], algorithm: :concurrently,
      where: "workflow_state <> 'deleted'", name: "index_discussion_entries_active_on_user_id_and_topic"

    add_index :conversation_participants, [:user_id], algorithm: :concurrently,
      where: "workflow_state = 'unread'", name: "index_conversation_participants_unread_on_user_id"

    add_index :assignments, [:duplication_started_at], algorithm: :concurrently,
      where: "workflow_state = 'migrating' AND duplication_started_at IS NOT NULL",
      name: "index_assignments_duplicating_on_started_at"

    add_index :submissions, [:user_id], algorithm: :concurrently,
      where: "(score IS NOT NULL AND workflow_state = 'graded') OR excused = TRUE",
      name: "index_submissions_graded_or_excused_on_user_id"
  end
end
