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

class MigrationHelpers::StudentVisibilities::StudentVisibilitiesV5
  def initialize(view_name, model)
    @view_name = view_name
    @model = model
  end

  def view_sql
    <<~SQL.squish
      CREATE OR REPLACE VIEW #{@view_name} AS

      /* if only_visible_to_overrides is false, or there's related
        modules with no overrides, then everyone can see it */
      SELECT DISTINCT o.id as #{id_column_name},
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = o.context_id
        AND o.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      #{module_join_sql("workflow_state<>'deleted'") unless @model == ContextModule}
      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON #{(@model == ContextModule) ? "o" : "m"}.id = ao.context_module_id
        AND ao.workflow_state = 'active'
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
        #{"AND COALESCE(o.only_visible_to_overrides, 'false') = 'false'" unless @model == ContextModule}
        AND (#{(@model == ContextModule) ? "o" : "m"}.id IS NULL OR (ao.context_module_id IS NULL AND #{(@model == ContextModule) ? "o" : "m"}.workflow_state = 'active'))

      /* only assignments can have group overrides */
      #{group_overrides_sql if @model == Assignment}

      UNION

      /* section overrides and related module section overrides */
      SELECT DISTINCT o.id as #{id_column_name},
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = o.context_id
        AND o.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      #{module_join_sql("workflow_state = 'active'") unless @model == ContextModule}
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_section_id = ao.set_id
        AND ao.set_type = 'CourseSection'
        AND (ao.#{id_column_name} = o.id #{"OR m.id = ao.context_module_id" unless @model == ContextModule})
        AND ao.workflow_state = 'active'
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
        #{"AND (m.id IS NOT NULL OR o.only_visible_to_overrides = 'true')" unless @model == ContextModule}
        AND ao.unassign_item = FALSE

      /* remove students with unassigned section overrides */
      #{remove_unassign_section_sql unless @model == ContextModule}

      UNION

      /* ADHOC overrides and related module ADHOC overrides */
      SELECT DISTINCT o.id as #{id_column_name},
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = o.context_id
        AND o.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      #{module_join_sql("workflow_state = 'active'") unless @model == ContextModule}
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON (ao.#{id_column_name} = o.id #{"OR m.id = ao.context_module_id" unless @model == ContextModule})
        AND ao.set_type = 'ADHOC'
        AND ao.workflow_state = 'active'
      INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON ao.id = aos.assignment_override_id
        AND aos.user_id = e.user_id
        AND aos.workflow_state <> 'deleted'
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
        #{"AND (m.id IS NOT NULL OR o.only_visible_to_overrides = 'true')" unless @model == ContextModule}
        AND ao.unassign_item = FALSE

      /* remove students with unassigned ADHOC overrides */
      #{remove_unassign_adhoc_sql unless @model == ContextModule}

      /* course overrides */
      #{course_overrides_sql unless @model == ContextModule}
    SQL
  end

  private

  def module_join_sql(module_filter)
    <<~SQL.squish
      LEFT JOIN #{ContentTag.quoted_table_name} t
        ON t.content_id = o.id
        AND t.content_type = '#{@model}'
        AND t.tag_type='context_module'
        AND t.workflow_state<>'deleted'
      LEFT JOIN #{ContextModule.quoted_table_name} m
        ON m.id = t.context_module_id
        AND m.#{module_filter}
    SQL
  end

  def group_overrides_sql
    <<~SQL.squish
      UNION
      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{Assignment.quoted_table_name} a
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = a.context_id
        AND a.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON a.id = ao.assignment_id
        AND ao.set_type = 'Group'
      INNER JOIN #{Group.quoted_table_name} g
        ON g.id = ao.set_id
      INNER JOIN #{GroupMembership.quoted_table_name} gm
        ON gm.group_id = g.id
        AND gm.user_id = e.user_id
      WHERE gm.workflow_state <> 'deleted'
        AND g.workflow_state <> 'deleted'
        AND ao.workflow_state = 'active'
        AND a.workflow_state NOT IN ('deleted','unpublished')
        AND a.only_visible_to_overrides = 'true'
    SQL
  end

  def remove_unassign_section_sql
    <<~SQL.squish
      EXCEPT
      SELECT DISTINCT o.id as #{id_column_name},
          e.user_id as user_id,
          e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = o.context_id
          AND o.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON e.course_section_id = ao.set_id
          AND ao.set_type = 'CourseSection'
          AND ao.#{id_column_name} = o.id
          AND ao.workflow_state = 'active'
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
          AND ao.unassign_item = TRUE
    SQL
  end

  def remove_unassign_adhoc_sql
    <<~SQL.squish
      EXCEPT
      SELECT DISTINCT o.id as #{id_column_name},
          e.user_id as user_id,
          e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
          ON e.course_id = o.context_id
          AND o.context_type = 'Course'
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
          ON o.id = ao.#{id_column_name}
          AND ao.set_type = 'ADHOC'
          AND ao.workflow_state = 'active'
      INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
          ON ao.id = aos.assignment_override_id
          AND aos.user_id = e.user_id
          AND aos.workflow_state <> 'deleted'
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
          AND ao.unassign_item = TRUE
    SQL
  end

  def course_overrides_sql
    <<~SQL.squish
      UNION
      SELECT DISTINCT o.id as #{id_column_name},
        e.user_id as user_id,
        e.course_id as course_id
      FROM #{@model.quoted_table_name} o
      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = o.context_id
        AND o.context_type = 'Course'
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')
      INNER JOIN #{AssignmentOverride.quoted_table_name} ao
        ON e.course_id = ao.set_id
        AND ao.set_type = 'Course'
        AND o.id = ao.#{id_column_name}
      WHERE o.workflow_state NOT IN ('deleted','unpublished')
        AND ao.workflow_state = 'active'
    SQL
  end

  def id_column_name
    # i.e., Quizzes::Quiz => quiz_id
    "#{@model.class_name.demodulize.underscore}_id"
  end
end
