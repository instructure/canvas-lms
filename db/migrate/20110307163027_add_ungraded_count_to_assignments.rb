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

class AddUngradedCountToAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :needs_grading_count, :integer, :default => 0

    update <<-SQL
      UPDATE #{Assignment.quoted_table_name} SET needs_grading_count = COALESCE((
        SELECT COUNT(*)
        FROM #{Submission.quoted_table_name} s
        INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = s.user_id AND e.workflow_state = 'active'
        WHERE s.assignment_id = assignments.id
          AND e.course_id = assignments.context_id
          AND (s.score IS NULL
            OR NOT grade_matches_current_submission
            OR s.workflow_state = 'submitted'
            OR s.workflow_state = 'pending_review'
          )
          AND s.submission_type IS NOT NULL
          AND s.workflow_state <> 'deleted'
      ), 0)
      SQL
  end

  def self.down
    remove_column :assignments, :needs_grading_count
  end
end
