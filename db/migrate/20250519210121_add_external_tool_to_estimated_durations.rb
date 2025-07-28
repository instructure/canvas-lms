# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AddExternalToolToEstimatedDurations < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_reference :estimated_durations,
                  :external_tool,
                  foreign_key: { to_table: :context_external_tools },
                  index: {
                    where: "external_tool_id IS NOT NULL",
                    unique: true,
                    algorithm: :concurrently,
                    if_not_exists: true
                  },
                  if_not_exists: true

    check_sql = <<~SQL.squish
      (
        (discussion_topic_id IS NOT NULL)::int +
        (assignment_id IS NOT NULL)::int +
        (attachment_id IS NOT NULL)::int +
        (quiz_id IS NOT NULL)::int +
        (wiki_page_id IS NOT NULL)::int +
        (content_tag_id IS NOT NULL)::int +
        (external_tool_id IS NOT NULL)::int
      ) = 1
    SQL

    add_check_constraint :estimated_durations,
                         check_sql,
                         name: "chk_one_foreign_key_is_present",
                         validate: false,
                         if_not_exists: true
    validate_constraint :estimated_durations, "chk_one_foreign_key_is_present"

    # remove the old constraint
    remove_check_constraint :estimated_durations,
                            name: "check_that_exactly_one_foreign_key_is_present",
                            if_exists: true
  end

  def down
    # We have to remove the external tool estimated durations because they won't satisfy the old constraint.
    EstimatedDuration.where.not(external_tool_id: nil).delete_all

    remove_reference :estimated_durations,
                     :external_tool,
                     foreign_key: { to_table: :context_external_tools },
                     index: true

    check_sql = <<~SQL.squish
      (
        (discussion_topic_id IS NOT NULL)::int +
        (assignment_id IS NOT NULL)::int +
        (attachment_id IS NOT NULL)::int +
        (quiz_id IS NOT NULL)::int +
        (wiki_page_id IS NOT NULL)::int +
        (content_tag_id IS NOT NULL)::int
      ) = 1
    SQL

    # add back the old constraint
    add_check_constraint :estimated_durations,
                         check_sql,
                         name: "check_that_exactly_one_foreign_key_is_present",
                         if_not_exists: true,
                         validate: false
    validate_constraint :estimated_durations, "check_that_exactly_one_foreign_key_is_present"

    # remove the newly added constraint
    remove_check_constraint :estimated_durations, name: "chk_one_foreign_key_is_present", if_exists: true
  end
end
