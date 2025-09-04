# frozen_string_literal: true

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

class StandarizePolymorphicCheckConstraints < ActiveRecord::Migration[7.2]
  tag :postdeploy
  disable_ddl_transaction!

  def replace_check_constraint(table, old_name, new_name, sql)
    if old_name == new_name
      temp_name = "#{old_name}_old"
      rename_constraint(table, old_name, temp_name, if_exists: true) unless check_constraint_exists?(table, name: temp_name)
    else
      temp_name = old_name
    end
    add_check_constraint table, sql, name: new_name, if_not_exists: true, validate: false
    validate_constraint table, new_name

    remove_check_constraint table, temp_name, if_exists: true
  end

  def up
    add_polymorphic_check_constraint :accessibility_issues,
                                     :context,
                                     %i[wiki_page assignment attachment],
                                     replace: true,
                                     null: false,
                                     delay_validation: true,
                                     if_not_exists: true
    add_polymorphic_check_constraint :accessibility_resource_scans,
                                     :context,
                                     %i[wiki_page assignment attachment],
                                     replace: true,
                                     null: false,
                                     delay_validation: true,
                                     if_not_exists: true
    add_polymorphic_check_constraint :estimated_durations,
                                     :context,
                                     %i[assignment attachment content_tag discussion_topic wiki_page quiz external_tool],
                                     replace: "chk_one_foreign_key_is_present",
                                     null: false,
                                     delay_validation: true,
                                     if_not_exists: true
    add_polymorphic_check_constraint :lti_context_controls,
                                     :context,
                                     %i[account course],
                                     replace: true,
                                     null: false,
                                     delay_validation: true,
                                     if_not_exists: true
    add_polymorphic_check_constraint :rubric_imports,
                                     :context,
                                     %i[account course],
                                     replace: "chk_require_association",
                                     null: false,
                                     delay_validation: true,
                                     if_not_exists: true
  end

  def down
    replace_check_constraint :rubric_imports,
                             "chk_require_context",
                             "chk_require_association",
                             <<~SQL.squish
                               (account_id IS NOT NULL OR
                               course_id IS NOT NULL) AND NOT
                               (account_id IS NOT NULL AND course_id IS NOT NULL)
                             SQL
    replace_check_constraint :lti_context_controls,
                             "chk_require_context",
                             "chk_require_context",
                             <<~SQL.squish
                               (account_id IS NOT NULL OR
                               course_id IS NOT NULL) AND NOT
                               (account_id IS NOT NULL AND course_id IS NOT NULL)
                             SQL
    replace_check_constraint :estimated_durations,
                             "chk_require_context",
                             "chk_one_foreign_key_is_present",
                             <<~SQL.squish
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
    replace_check_constraint :accessibility_resource_scan,
                             "chk_require_context",
                             "chk_require_context",
                             <<~SQL.squish
                               (wiki_page_id IS NOT NULL AND assignment_id IS NULL AND attachment_id IS NULL) OR
                               (wiki_page_id IS NULL AND assignment_id IS NOT NULL AND attachment_id IS NULL) OR
                               (wiki_page_id IS NULL AND assignment_id IS NULL AND attachment_id IS NOT NULL)
                             SQL
    replace_check_constraint :accessibility_issues,
                             "chk_require_context",
                             "chk_require_context",
                             <<~SQL.squish
                               (wiki_page_id IS NOT NULL AND assignment_id IS NULL AND attachment_id IS NULL) OR
                               (wiki_page_id IS NULL AND assignment_id IS NOT NULL AND attachment_id IS NULL) OR
                               (wiki_page_id IS NULL AND assignment_id IS NULL AND attachment_id IS NOT NULL)
                             SQL
  end
end
