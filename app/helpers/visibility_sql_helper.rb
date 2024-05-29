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

# shared SQL between AssignmentVisibleToStudentRepository,  DiscussionTopicVisibleToStudentRepository, WikiPageVisibleToStudentRepository, etc
module VisibilitySqlHelper
  class << self
    def enrollment_join_sql
      <<~SQL.squish
        JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = o.context_id
        AND o.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      SQL
    end

    # NOTE: the method for ContextModule is different
    def module_items_join_sql(content_tag_type:)
      <<~SQL.squish
        LEFT JOIN #{ContentTag.quoted_table_name} t
                ON t.content_id = o.id
                AND t.content_type = '#{content_tag_type}'
                AND t.tag_type='context_module'
                AND t.workflow_state<>'deleted'
              LEFT JOIN #{ContextModule.quoted_table_name} m
                ON m.id = t.context_module_id
                AND m.workflow_state<>'deleted'
      SQL
    end

    def context_module_join_sql
      <<~SQL.squish
        LEFT JOIN #{ContextModule.quoted_table_name} m
        ON m.id = t.context_module_id
        AND m.workflow_state<>'deleted'
      SQL
    end

    def assignment_override_section_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_section_id = ao.set_id
        AND ao.set_type = 'CourseSection'
        AND (ao.#{id_column_name} = o.id OR m.id = ao.context_module_id)
        AND ao.workflow_state = 'active'
      SQL
    end

    def section_override_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
        AND o.workflow_state NOT IN ('deleted','unpublished')
        AND (m.id IS NOT NULL OR o.only_visible_to_overrides = 'true')
        AND ao.unassign_item = FALSE
      SQL
    end

    def assignment_override_adhoc_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON (ao.#{id_column_name} = o.id OR m.id = ao.context_module_id)
        AND ao.set_type = 'ADHOC'
        AND ao.workflow_state = 'active'
      SQL
    end

    def adhoc_override_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
        AND o.workflow_state NOT IN ('deleted','unpublished')
        AND (m.id IS NOT NULL OR o.only_visible_to_overrides = 'true')
        AND ao.unassign_item = FALSE
      SQL
    end

    def assignment_override_unassign_section_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_section_id = ao.set_id
        AND ao.set_type = 'CourseSection'
        AND ao.#{id_column_name} = o.id
        AND ao.workflow_state = 'active'
      SQL
    end

    def assignment_override_unassign_section_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
        AND o.workflow_state NOT IN ('deleted','unpublished')
        AND ao.unassign_item = TRUE
      SQL
    end

    # assignment_override_unassign_adhoc_join_sql
    def assignment_override_unassign_adhoc_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
            ON o.id = ao.#{id_column_name}
            AND ao.set_type = 'ADHOC'
            AND ao.workflow_state = 'active'
        INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
            ON ao.id = aos.assignment_override_id
            AND aos.user_id = e.user_id
            AND aos.workflow_state <> 'deleted'
      SQL
    end

    def assignment_override_course_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_id = ao.set_id
        AND ao.set_type = 'Course'
        AND o.id = ao.#{id_column_name}
      SQL
    end

    def assignment_override_everyone_join_sql
      <<~SQL.squish
        LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
          ON m.id = ao.context_module_id
          AND ao.workflow_state = 'active'
      SQL
    end

    def assignment_override_everyone_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
          AND o.workflow_state NOT IN ('deleted','unpublished')
          AND COALESCE(o.only_visible_to_overrides, 'false') = 'false'
          AND (m.id IS NULL OR (ao.context_module_id IS NULL AND m.workflow_state <> 'deleted'))
      SQL
    end

    def assignment_override_unassign_adhoc_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
          AND o.workflow_state NOT IN ('deleted','unpublished')
          AND ao.unassign_item = TRUE
      SQL
    end

    def assignment_override_student_join_sql
      <<~SQL.squish
        INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON ao.id = aos.assignment_override_id
        AND aos.user_id = e.user_id
        AND aos.workflow_state <> 'deleted'
      SQL
    end

    def course_override_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
          AND o.workflow_state NOT IN ('deleted','unpublished')
          AND ao.workflow_state = 'active'
      SQL
    end
  end
end
