# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class RemoveOldSubmissionNeedsGradingIndex < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # Submission.needs_grading was updated and a new index was created,
    # but the old index was never removed and is no longer used
    remove_index :submissions, :assignment_id, name: "index_submissions_on_assignment_id", where: <<~SQL.squish, algorithm: :concurrently, if_exists: true
      submission_type IS NOT NULL
      AND (workflow_state = 'pending_review'
        OR (workflow_state = 'submitted'
          AND (score IS NULL OR NOT grade_matches_current_submission)
        )
      )
    SQL
  end
end
