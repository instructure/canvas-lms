# frozen_string_literal: true

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

# @API Late Policy
# Manage a course's late policy.
#
# @model LatePolicy
#   {
#     "id": "LatePolicy",
#     "required": "course_id",
#     "properties": {
#       "id": {
#         "description": "the unique identifier for the late policy",
#         "example": 123,
#         "type": "integer"
#       },
#       "course_id": {
#         "description": "the unique identifier for the course",
#         "example": 123,
#         "type": "integer"
#       },
#       "missing_submission_deduction_enabled": {
#         "description": "whether to enable missing submission deductions",
#         "example": true,
#         "type": "boolean",
#         "default": false
#       },
#       "missing_submission_deduction": {
#         "description": "amount of percentage points to deduct",
#         "example": 12.34,
#         "type": "number",
#         "default": 0,
#         "minimum": 0,
#         "maximum": 100
#       },
#       "late_submission_deduction_enabled": {
#         "description": "whether to enable late submission deductions",
#         "example": true,
#         "type": "boolean",
#         "default": false
#       },
#       "late_submission_deduction": {
#         "description": "amount of percentage points to deduct per late_submission_interval",
#         "example": 12.34,
#         "type": "number",
#         "default": 0,
#         "minimum": 0,
#         "maximum": 100
#       },
#       "late_submission_interval": {
#         "description": "time interval for late submission deduction",
#         "example": "hour",
#         "type": "string",
#         "default": "day",
#         "enum": ["hour", "day"]
#       },
#       "late_submission_minimum_percent_enabled": {
#         "description": "whether to enable late submission minimum percent",
#         "example": true,
#         "type": "boolean",
#         "default": false
#       },
#       "late_submission_minimum_percent": {
#         "description": "the minimum score a submission can receive in percentage points",
#         "example": 12.34,
#         "type": "number",
#         "default": 0,
#         "minimum": 0,
#         "maximum": 100
#       },
#       "created_at": {
#         "description": "the time at which this late policy was originally created",
#         "example": "2012-07-01T23:59:00-06:00",
#         "type": "datetime"
#       },
#       "updated_at": {
#         "description": "the time at which this late policy was last modified in any way",
#         "example": "2012-07-01T23:59:00-06:00",
#         "type": "datetime"
#       }
#     }
#   }
#
class LatePolicyController < ApplicationController
  before_action :require_user
  before_action :require_manage_grades_for_course, except: [:show]
  before_action :require_view_or_manage_grades_for_course, only: [:show]

  rescue_from "RecordAlreadyExists", with: :record_already_exists

  # @API Get a late policy
  #
  # Returns the late policy for a course.
  #
  # @example_response
  #   {
  #     "late_policy": LatePolicy
  #   }
  #
  def show
    raise ActiveRecord::RecordNotFound if course.late_policy.blank?

    render json: serialize(course.late_policy)
  end

  # @API Create a late policy
  #
  # Create a late policy. If the course already has a late policy, a
  # bad_request is returned since there can only be one late policy
  # per course.
  #
  # @argument late_policy[missing_submission_deduction_enabled] [Boolean]
  #   Whether to enable the missing submission deduction late policy.
  #
  # @argument late_policy[missing_submission_deduction] [Number]
  #   How many percentage points to deduct from a missing submission.
  #
  # @argument late_policy[late_submission_deduction_enabled] [Boolean]
  #   Whether to enable the late submission deduction late policy.
  #
  # @argument late_policy[late_submission_deduction] [Number]
  #   How many percentage points to deduct per the late submission interval.
  #
  # @argument late_policy[late_submission_interval] [String]
  #   The interval for late policies.
  #
  # @argument late_policy[late_submission_minimum_percent_enabled] [Boolean]
  #   Whether to enable the late submission minimum percent for a late policy.
  #
  # @argument late_policy[late_submission_minimum_percent] [Number]
  #   The minimum grade a submissions can have in percentage points.
  #
  # @example_response
  #   {
  #     "late_policy": LatePolicy
  #   }
  #
  def create
    increment_request_cost(200)

    raise RecordAlreadyExists if course.late_policy.present?

    late_policy = course.build_late_policy(late_policy_params)

    if late_policy.save
      render json: serialize(late_policy), status: :created
    else
      render json: late_policy.errors, status: :unprocessable_entity
    end
  end

  # @API Patch a late policy
  #
  # Patch a late policy. No body is returned upon success.
  #
  # @argument late_policy[missing_submission_deduction_enabled] [Boolean]
  #   Whether to enable the missing submission deduction late policy.
  #
  # @argument late_policy[missing_submission_deduction] [Number]
  #   How many percentage points to deduct from a missing submission.
  #
  # @argument late_policy[late_submission_deduction_enabled] [Boolean]
  #   Whether to enable the late submission deduction late policy.
  #
  # @argument late_policy[late_submission_deduction] [Number]
  #   How many percentage points to deduct per the late submission interval.
  #
  # @argument late_policy[late_submission_interval] [String]
  #   The interval for late policies.
  #
  # @argument late_policy[late_submission_minimum_percent_enabled] [Boolean]
  #   Whether to enable the late submission minimum percent for a late policy.
  #
  # @argument late_policy[late_submission_minimum_percent] [Number]
  #   The minimum grade a submissions can have in percentage points.
  #
  def update
    increment_request_cost(200)

    raise ActiveRecord::RecordNotFound if course.late_policy.blank?

    if course.late_policy.update(late_policy_params)
      head :no_content
    else
      render json: course.late_policy.errors, status: :unprocessable_entity
    end
  end

  private

  def require_manage_grades_for_course
    render_json_unauthorized unless course.grants_right?(@current_user, :manage_grades)
  end

  def require_view_or_manage_grades_for_course
    render_json_unauthorized unless course.grants_any_right?(@current_user, :manage_grades, :view_all_grades)
  end

  def course
    @course ||= api_find(Course.active, params[:id])
  end

  def late_policy_params
    params.require(:late_policy).permit(
      :missing_submission_deduction_enabled,
      :missing_submission_deduction,
      :late_submission_deduction_enabled,
      :late_submission_deduction,
      :late_submission_interval,
      :late_submission_minimum_percent_enabled,
      :late_submission_minimum_percent
    )
  end

  def serialize(late_policy)
    LatePolicySerializer.new(late_policy, controller: self)
  end

  def record_already_exists
    status = :bad_request
    message = "only one late policy per course is allowed"
    render json: { status:, errors: [{ message: }] }, status:
  end

  class RecordAlreadyExists < ActiveRecord::ActiveRecordError; end
end
