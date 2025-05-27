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
    def enrollment_join_sql(include_concluded: true)
      if include_concluded
        <<~SQL.squish
          JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = o.context_id
          AND o.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
        SQL
      else
        <<~SQL.squish
          JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = o.context_id
          AND o.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('completed', 'deleted', 'rejected', 'inactive')
        SQL
      end
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

    def assignment_override_non_collaborative_group_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON (ao.#{id_column_name} = o.id OR m.id = ao.context_module_id)
          AND ao.set_type = 'Group'
          AND ao.workflow_state = 'active'
        INNER JOIN #{Group.quoted_table_name} g
          ON g.id = ao.set_id
          AND g.non_collaborative = TRUE
        INNER JOIN #{GroupMembership.quoted_table_name} gm
          ON gm.group_id = g.id
          AND gm.user_id = e.user_id
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

    def assignment_override_unassign_non_collaborative_group_join_sql(id_column_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON o.id = ao.#{id_column_name}
          AND ao.set_type = 'Group'
          AND ao.workflow_state = 'active'
        INNER JOIN #{Group.quoted_table_name} g
          ON g.id = ao.set_id
          AND g.non_collaborative = TRUE
        INNER JOIN #{GroupMembership.quoted_table_name} gm
          ON gm.group_id = g.id
          AND gm.user_id = e.user_id
      SQL
    end

    def assignment_override_non_collaborative_group_filter_sql(filter_condition_sql:)
      <<~SQL.squish
        WHERE #{filter_condition_sql}
        AND o.workflow_state NOT IN ('deleted','unpublished')
        AND (m.id IS NOT NULL OR o.only_visible_to_overrides = 'true')
        AND ao.unassign_item = FALSE
      SQL
    end

    def assignment_override_unassign_filter_sql(filter_condition_sql:)
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
          AND o.only_visible_to_overrides = 'false'
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

    def assign_to_differentiation_tags_enabled?(course_ids)
      # alternatively this could throw a error if course_ids is nil. However, this feature flag check will go
      # away once the feature is fully enabled.
      return false unless course_ids.present?

      account_ids = Course.where(id: course_ids).distinct.pluck(:account_id).uniq
      accounts = Account.where(id: account_ids).to_a

      accounts.any? { |account| account.feature_enabled?(:assign_to_differentiation_tags) }
    end

    def full_section_with_left_joins_sql(filter_condition_sql:, id_column_name:, content_tag_type:)
      <<~SQL.squish
        /* join context modules */
        #{module_items_join_sql(content_tag_type:)}

        /* join assignment overrides (assignment or related context module) for CourseSection */
        #{assignment_override_section_join_sql(id_column_name:)}

        /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
        #{section_override_filter_sql(filter_condition_sql:)}
      SQL
    end

    def full_section_without_left_joins_sql(filter_condition_sql:, id_column_name:, table_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON e.course_section_id = ao.set_id
              AND ao.set_type = 'CourseSection'
              AND ao.#{id_column_name} = o.id
              AND ao.workflow_state = 'active'
        WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
              AND ao.unassign_item = FALSE

        UNION

        /* Module Section Overrides */
        #{learning_object_select_sql(table_name:, id_column_name:)}

        /* join active student enrollments */
        #{enrollment_join_sql}

        #{content_tag_join_sql(table_name:)}

        JOIN #{ContextModule.quoted_table_name} m
                      ON m.id = t.context_module_id
                      AND m.workflow_state<>'deleted'
        JOIN #{AssignmentOverride.quoted_table_name} ao
              ON e.course_section_id = ao.set_id
              AND ao.set_type = 'CourseSection'
              AND m.id = ao.context_module_id
              AND ao.workflow_state = 'active'
        WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
      SQL
    end

    def full_adhoc_with_left_joins_sql(filter_condition_sql:, id_column_name:, content_tag_type:)
      <<~SQL.squish
        /* join context modules */
        #{module_items_join_sql(content_tag_type:)}

        /* join assignment override for 'ADHOC' */
        #{assignment_override_adhoc_join_sql(id_column_name:)}

        /* join AssignmentOverrideStudent */
        #{assignment_override_student_join_sql}

        /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
        #{adhoc_override_filter_sql(filter_condition_sql:)}
      SQL
    end

    def full_adhoc_without_left_joins_sql(filter_condition_sql:, id_column_name:, table_name:)
      <<~SQL.squish
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON ao.#{id_column_name} = o.id
              AND ao.set_type = 'ADHOC'
              AND ao.workflow_state = 'active'
        INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
              ON ao.id = aos.assignment_override_id
              AND aos.user_id = e.user_id
              AND aos.workflow_state <> 'deleted'
        WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
              AND ao.unassign_item = FALSE

        UNION

        /* Module Adhoc Overrides */
        #{learning_object_select_sql(table_name:, id_column_name:)}
        /* join active student enrollments */
        #{enrollment_join_sql}

        #{content_tag_join_sql(table_name:)}

        JOIN #{ContextModule.quoted_table_name} m
              ON m.id = t.context_module_id
              AND m.workflow_state<>'deleted'
        INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON m.id = ao.context_module_id
              AND ao.set_type = 'ADHOC'
              AND ao.workflow_state = 'active'
        INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
              ON ao.id = aos.assignment_override_id
              AND aos.user_id = e.user_id
              AND aos.workflow_state <> 'deleted'
        WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
      SQL
    end

    def content_tag_join_sql(table_name:)
      if table_name == Assignment
        <<~SQL.squish
          JOIN all_tags t
              ON o.id = t.assignment_id
        SQL
      else
        <<~SQL.squish
          JOIN #{ContentTag.quoted_table_name} t
                  ON t.content_id = o.id
                  AND t.content_type = '#{table_name.name}'
                  AND t.tag_type='context_module'
                  AND t.workflow_state<>'deleted'
        SQL
      end
    end

    def learning_object_select_sql(table_name:, id_column_name:)
      <<~SQL.squish
        SELECT DISTINCT o.id as #{id_column_name},
        e.user_id as user_id,
        e.course_id as course_id
        FROM #{table_name.quoted_table_name} o
      SQL
    end
  end
end
