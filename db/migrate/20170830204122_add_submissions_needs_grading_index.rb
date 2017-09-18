#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AddSubmissionsNeedsGradingIndex < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # see Submission.needs_grading; duplicated instead of called directly so the migration doesn't
    # change even if the query does
    add_index :submissions, :assignment_id, name: 'index_submissions_needs_grading', algorithm: :concurrently, where: <<-SQL
      submissions.submission_type IS NOT NULL
      AND (submissions.excused = 'f' OR submissions.excused IS NULL)
      AND (submissions.workflow_state = 'pending_review'
        OR (submissions.workflow_state IN ('submitted', 'graded')
          AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)
        )
      )
    SQL
  end
end
