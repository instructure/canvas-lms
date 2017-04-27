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

module DataFixup::FixUngradedCountsIncludeQuizEssays
  def self.run
    Assignment.find_ids_in_batches do |ids|
      Assignment.connection.execute(Assignment.send(:sanitize_sql_array, [<<-SQL, ids]))
        UPDATE assignments SET needs_grading_count = COALESCE((
          SELECT COUNT(DISTINCT s.id)
          FROM submissions s
          INNER JOIN enrollments e ON e.user_id = s.user_id AND e.workflow_state = 'active'
          WHERE assignments.id IN (?)
            AND s.assignment_id = assignments.id
            AND e.course_id = assignments.context_id
            AND s.submission_type IS NOT NULL
            AND (s.workflow_state = 'pending_review'
              OR (s.workflow_state = 'submitted' 
                AND (s.score IS NULL OR NOT s.grade_matches_current_submission)
              )
            )
        ), 0)
        SQL
    end
  end
end
