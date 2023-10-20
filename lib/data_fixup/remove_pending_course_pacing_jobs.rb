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

module DataFixup::RemovePendingCoursePacingJobs
  def self.run(start_id, end_id)
    Progress.where(tag: "course_pace_publish", workflow_state: "queued", id: start_id..end_id).in_batches(of: 1000) do |queued_progress|
      not_stuck_jobs = Delayed::Job.where(id: queued_progress.pluck(:delayed_job_id)).pluck(:id)
      stuck_progress = queued_progress.where.not(delayed_job_id: not_stuck_jobs)

      stuck_progress.where(workflow_state: "queued").update_all(workflow_state: "failed")
    end
  end
end
