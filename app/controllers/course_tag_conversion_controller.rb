# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class CourseTagConversionController < ApplicationController
  include DifferentiationTag

  before_action :require_user
  before_action :require_context
  before_action :check_authorized_action

  def convert_tag_overrides_to_adhoc_overrides
    existing_job = active_conversion_job
    if existing_job
      return render json: { error: "A tag override conversion job is already in progress for this course." }, status: :conflict
    end

    # Dont allow conversion if the account allows assignment to differentiation tags
    if @context.account.allow_assign_to_differentiation_tags?
      return render json: { error: "Cannot perform conversion for courses belonging to accounts that allow assignment via differentiation tags" }, status: :bad_request
    end

    DifferentiationTag::Jobs::Workers::TagOverrideConverterWorker.start_job(@context)

    head :no_content
  end

  def conversion_job_status
    job = active_conversion_job
    if job
      render json: { workflow_state: job.workflow_state, progress: job.completion, }, status: :ok
    else
      render json: { error: "No active override conversion job found for this course." }, status: :not_found
    end
  end

  private

  def active_conversion_job
    @context.progresses.find_by(tag: DifferentiationTag::DELAYED_JOB_TAG, workflow_state: ["queued", "running"])
  end

  def check_authorized_action
    authorized = @context.grants_any_right?(@current_user, @current_session, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)
    render json: { error: "Unauthorized" }, status: :forbidden unless authorized
  end
end
