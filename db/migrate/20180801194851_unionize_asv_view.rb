#
# Copyright (C) 2011 - present Instructure, Inc.
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

class UnionizeAsvView < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    self.connection.execute(<<-SQL)
      CREATE OR REPLACE VIEW #{connection.quote_table_name('assignment_student_visibilities')} AS
      WITH overrides AS (
        SELECT DISTINCT ON (o.assignment_id, o.user_id) *
        FROM (
          -- Individual overrides
          SELECT ao.assignment_id, aos.user_id, ao.due_at, ao.due_at_overridden, 1 AS priority
          FROM #{AssignmentOverride.quoted_table_name} ao
          INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} aos ON ao.id = aos.assignment_override_id AND ao.set_type = 'ADHOC'
          WHERE ao.workflow_state = 'active'
            AND aos.workflow_state <> 'deleted'
          UNION
          -- Group overrides
          SELECT ao.assignment_id, gm.user_id, ao.due_at, ao.due_at_overridden, 1 AS priority
          FROM #{AssignmentOverride.quoted_table_name} ao
          INNER JOIN #{Group.quoted_table_name} g ON g.id = ao.set_id AND ao.set_type = 'Group'
          INNER JOIN #{GroupMembership.quoted_table_name} gm ON gm.group_id = ao.set_id AND ao.set_type = 'Group' AND gm.group_id = g.id
          WHERE gm.workflow_state <> 'deleted'
            AND g.workflow_state <> 'deleted'
            AND ao.workflow_state = 'active'
          UNION
          -- Section overrides
          SELECT ao.assignment_id, e.user_id, ao.due_at, ao.due_at_overridden, 1 AS priority
          FROM #{AssignmentOverride.quoted_table_name} ao
          INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_section_id = ao.set_id AND ao.set_type = 'CourseSection'
          WHERE e.workflow_state NOT IN ('rejected', 'deleted', 'inactive')
            AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
            AND ao.workflow_state = 'active'
          UNION
          -- Everyone else overrides
          SELECT a.id, e.user_id, a.due_at, FALSE AS due_at_overridden, 2 AS priority
          FROM #{Assignment.quoted_table_name} a
          INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_id = a.context_id
          WHERE e.workflow_state NOT IN ('rejected', 'deleted', 'inactive')
            AND e.type in ('StudentEnrollment', 'StudentViewEnrollment')
            AND NOT a.only_visible_to_overrides
          UNION
          -- Already submitted assignments, user may no longer have access
          SELECT a.id, s.user_id, a.due_at, FALSE AS due_at_overridden, 3 AS priority
          FROM #{Assignment.quoted_table_name} a
          INNER JOIN #{Submission.quoted_table_name} s ON s.assignment_id = a.id
          WHERE s.workflow_state NOT IN ('deleted', 'unsubmitted')
        ) o
        ORDER BY o.user_id ASC, o.assignment_id ASC, priority ASC, o.due_at_overridden DESC, o.due_at DESC NULLS FIRST
      )
      SELECT DISTINCT a.id AS assignment_id, overrides.user_id as user_id, a.context_id AS course_id
      FROM #{Assignment.quoted_table_name} a
      INNER JOIN overrides ON overrides.assignment_id = a.id
      WHERE a.workflow_state NOT IN ('deleted', 'unpublished')
    SQL
  end

  def down
    # find the groups first and then worry about group memberships
    self.connection.execute %(CREATE OR REPLACE VIEW #{connection.quote_table_name('assignment_student_visibilities')} AS
      SELECT DISTINCT a.id as assignment_id,
        e.user_id as user_id,
        c.id as course_id

      FROM #{Assignment.quoted_table_name} a

      JOIN #{Course.quoted_table_name} c
        ON a.context_id = c.id
        AND a.context_type = 'Course'

      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = c.id
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state NOT IN ('deleted', 'rejected', 'inactive')

      JOIN #{CourseSection.quoted_table_name} cs
        ON cs.course_id = c.id
        AND e.course_section_id = cs.id

      LEFT JOIN #{Group.quoted_table_name} g
        ON g.context_type = 'Course'
        AND g.context_id = c.id
        AND g.workflow_state = 'available'

      LEFT JOIN #{GroupMembership.quoted_table_name} gm
        ON gm.user_id = e.user_id
        AND gm.workflow_state = 'accepted'
        AND gm.group_id = g.id

      LEFT JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON aos.assignment_id = a.id
        AND aos.user_id = e.user_id
        AND aos.workflow_state = 'active'

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.assignment_id = a.id
        AND ao.workflow_state = 'active'
        AND (
          (ao.set_type = 'CourseSection' AND ao.set_id = cs.id)
          OR (ao.set_type = 'ADHOC' AND ao.set_id IS NULL AND ao.id = aos.assignment_override_id)
          OR (ao.set_type = 'Group' AND ao.set_id = g.id AND gm.id IS NOT NULL)
        )

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.workflow_state NOT IN ('deleted', 'unsubmitted')

      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND(
          ( a.only_visible_to_overrides = 'true' AND (ao.id IS NOT NULL OR s.id IS NOT NULL))
          OR (COALESCE(a.only_visible_to_overrides, 'false') = 'false')
        )
      )
  end
end