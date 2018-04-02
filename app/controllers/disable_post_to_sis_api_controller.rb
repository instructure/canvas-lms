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

# @API SIS Integration
#
# Includes helpers for integration with SIS systems.
#
class DisablePostToSisApiController < ApplicationController

  before_action :require_authorized_user
  before_action :require_valid_grading_period, :if => :grading_period_exists?

  # @API Disable assignments currently enabled for grade export to SIS
  #
  # Disable all assignments flagged as "post_to_sis", with the option of making it
  # specific to a grading period, in a course.
  #
  # @argument course_id [Integer] The ID of the course.
  #
  # @argument grading_period_id [Integer] The ID of the grading period.
  #
  # On success, the response will be 204 No Content with an empty body.
  #
  # On failure, the response will be 400 Bad Request with a body of a specific
  # message.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/sis/courses/<course_id>/disable_post_to_sis' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0"
  #
  # For disabling assignments in a specific grading period
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/sis/courses/<course_id>/disable_post_to_sis' \
  #        -X PUT \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Length: 0" \
  #        -d 'grading_period_id=1'
  #
  def disable_post_to_sis
    assignments = published_assignments.where(post_to_sis: true).limit(1000)
    while assignments.update_all(post_to_sis: false) > 0 do end
    head :no_content
  end

  private

  def context
    @context ||=
      if params[:course_id]
        api_find(Course, params[:course_id])
      else
        fail ActiveRecord::RecordNotFound, 'unknown context type'
      end
  end

  def grading_period
    @grading_period ||=
      GradingPeriod.for(context, inherit: true).find_by(id: params[:grading_period_id])
  end

  def published_assignments
    assignments = Assignment.published.for_course(context)
    if grading_period
      assignments.where("due_at BETWEEN ? AND ? OR due_at IS NULL",
                        grading_period.start_date, grading_period.end_date)
    else
      assignments
    end
  end

  def grading_period_exists?
    params.has_key?(:grading_period_id) && !params[:grading_period_id].blank?
  end

  def require_authorized_user
    head :unauthorized unless context.grants_right?(@current_user, session, :manage_assignments)
  end

  def require_valid_grading_period
    body = {
      code: 'not_found',
      error: I18n.t('The Grading Period cannot be found')
    }
    render json: body, status: :bad_request if params[:grading_period_id] && grading_period.blank?
  end
end
