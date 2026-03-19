# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class AssignmentPeerReviewAllocationConversionController < ApplicationController
  before_action :require_user
  before_action :require_assignment
  before_action :check_authorized_action

  def convert_peer_review_allocations
    existing_job = active_conversion_job
    if existing_job
      return render json: { error: "A peer review conversion job is already in progress for this assignment." }, status: :conflict
    end

    type = params[:type]
    should_delete = value_to_boolean(params[:should_delete])

    PeerReview::Jobs::Workers::AllocationRuleConverterWorker.start_job(@assignment, type, should_delete:)

    head :no_content
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  end

  def conversion_job_status
    job = Progress.where(context: @assignment, tag: PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG).order(:created_at).last
    if job
      render json: { workflow_state: job.workflow_state, progress: job.completion }, status: :ok
    else
      render json: { error: "No peer review conversion job found for this assignment." }, status: :not_found
    end
  end

  private

  def require_assignment
    @course = Course.find(params[:course_id])
    @assignment = @course.assignments.find(params[:assignment_id])
  end

  def active_conversion_job
    Progress.find_by(context: @assignment, tag: PeerReview::Jobs::Workers::AllocationRuleConverterWorker::PROGRESS_TAG, workflow_state: ["queued", "running"])
  end

  def check_authorized_action
    authorized_action(@assignment, @current_user, :update)
  end
end
