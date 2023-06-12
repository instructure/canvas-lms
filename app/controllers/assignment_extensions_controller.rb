# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

# @API Assignment Extensions
#
# API for setting extensions on student assignment submissions. These cannot be
# set for discussion assignments or quizzes. For quizzes, use <a href="/doc/api/quiz_extensions.html">Quiz Extensions</a>
# instead.
#
# @model AssignmentExtension
#      {
#        "id": "AssignmentExtension",
#        "required": ["assignment_id", "user_id"],
#        "properties": {
#          "assignment_id": {
#            "description": "The ID of the Assignment the extension belongs to.",
#            "example": 2,
#            "type": "integer",
#            "format": "int64"
#          },
#          "user_id": {
#            "description": "The ID of the Student that needs the assignment extension.",
#            "example": 3,
#            "type": "integer",
#            "format": "int64"
#          },
#          "extra_attempts": {
#            "description": "Number of times the student is allowed to re-submit the assignment",
#            "example": 2,
#            "type": "integer",
#            "format": "int64"
#          }
#        }
#      }
class AssignmentExtensionsController < ApplicationController
  before_action :require_context, :require_user, :require_assignment

  # @API Set extensions for student assignment submissions
  #
  # @argument assignment_extensions[][user_id] [Required, Integer]
  #   The ID of the user we want to add assignment extensions for.
  #
  # @argument assignment_extensions[][extra_attempts] [Required, Integer]
  #   Number of times the student is allowed to re-take the assignment over the
  #   limit.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if you are not allowed to extend assignments for this course
  # * <b>400 Bad Request</b> if any of the extensions are invalid
  # @example_request
  #  {
  #    "assignment_extensions": [{
  #      "user_id": 3,
  #      "extra_attempts": 2
  #    },{
  #      "user_id": 2,
  #      "extra_attempts": 2
  #    }]
  #  }
  #
  # @example_response
  #  {
  #    "assignment_extensions": [AssignmentExtension]
  #  }
  #
  def create
    return unless authorized_action?(@assignment, @current_user, :create)

    unless params[:assignment_extensions].is_a?(Array)
      reject! "missing required key :assignment_extensions", 400
    end

    extensions_are_valid = params[:assignment_extensions].all? do |extension|
      extension.key?(:user_id) && extension.key?(:extra_attempts)
    end

    unless extensions_are_valid
      reject! ":assignment_extensions must be in this format: { user_id: 1, extra_attempts: 2 }", 400
    end

    # A hash where the key is the user id and the value is the extra attempts.
    # This allows us to avoid N+1 queries.
    assignment_extensions_map = {}
    params[:assignment_extensions].each { |ext| assignment_extensions_map[ext[:user_id].to_s] = ext[:extra_attempts] }

    submissions = @context.submissions.where(user_id: assignment_extensions_map.keys, assignment_id: @assignment.id)
    submissions.each { |submission| submission.extra_attempts = assignment_extensions_map[submission.user_id.to_s] }

    if submissions.all?(&:valid?) # Check if all are valid before saving
      submissions.each(&:save)
      assignment_extensions = submissions.map do |submission|
        { user_id: submission.user.id, extra_attempts: submission.extra_attempts }
      end

      render json: { assignment_extensions: }
    else
      invalid_submissions = submissions.reject(&:valid?)
      errors = invalid_submissions.map do |submission|
        { user_id: submission.user.id, errors: submission.errors.full_messages }
      end

      render json: { errors: }, status: :bad_request
    end
  end

  private

  def require_assignment
    @assignment = api_find(@context.active_assignments, params[:assignment_id])
  end
end
