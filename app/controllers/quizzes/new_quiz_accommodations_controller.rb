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
#

# @API New Quizzes Accommodations
#
# API for reading accommodations on New Quizzes (quiz_lti) assignments.
# Accommodations include extra time, extra attempts, and reduced choices.
# This endpoint proxies to the New Quizzes service to retrieve accommodation data.
#
# @model NewQuizAccommodation
#     {
#       "id": "NewQuizAccommodation",
#       "required": ["user_id"],
#       "properties": {
#         "user_id": {
#           "description": "The ID of the Student that has the accommodation.",
#           "example": 3,
#           "type": "integer",
#           "format": "int64"
#         },
#         "extra_time": {
#           "description": "Amount of extra time allowed for the quiz submission, in minutes.",
#           "example": 60,
#           "type": "integer",
#           "format": "int64"
#         },
#         "extra_attempts": {
#           "description": "Number of extra re-takes allowed over the multiple-attempt limit.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "reduce_choices_enabled": {
#           "description": "If true, removes one incorrect answer from multiple-choice questions.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
class Quizzes::NewQuizAccommodationsController < ApplicationController
  before_action :require_context
  before_action :authorize_read
  before_action :require_assignment
  before_action :require_new_quizzes_service

  # @API List accommodations for a New Quizzes assignment
  #
  # Returns all accommodations that have been set for the given
  # New Quizzes assignment. Proxies to the New Quizzes service.
  #
  # @argument user_id [Optional, Integer]
  #   If specified, only return the accommodation for this user.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if you are not allowed to manage this assignment
  # * <b>422 Unprocessable Entity</b> if the assignment is not a New Quizzes assignment
  # * <b>503 Service Unavailable</b> if the New Quizzes service is not configured
  #
  # @example_response
  #  {
  #    "accommodations": [NewQuizAccommodation]
  #  }
  #
  def index
    response = fetch_accommodations_from_service
    if response.nil?
      render json: { errors: [{ message: "Unable to communicate with New Quizzes service" }] },
             status: :bad_gateway
      return
    end
    unless response.code == 200
      render json: { errors: [{ message: "New Quizzes service error" }] }, status: :bad_gateway
      return
    end

    body = parse_response_body(response)
    return render_service_error if body.nil?

    participants = body.is_a?(Array) ? body : (body["participants"] || body["accommodations"] || [])
    accommodations = extract_accommodations(participants)
    if params[:user_id].present?
      accommodations = accommodations.select { |a| a[:user_id].to_s == params[:user_id].to_s }
    end
    render json: { accommodations: }
  end

  # @API Get accommodation for a specific user on a New Quizzes assignment
  #
  # Returns the accommodation for a specific user on the given
  # New Quizzes assignment.
  #
  # <b>Responses</b>
  #
  # * <b>200 OK</b> if the request was successful
  # * <b>403 Forbidden</b> if you are not allowed to manage this assignment
  # * <b>404 Not Found</b> if no accommodation exists for this user
  #
  # @example_response
  #  {
  #    "accommodation": NewQuizAccommodation
  #  }
  #
  def show
    response = fetch_accommodations_from_service
    if response.nil?
      render json: { errors: [{ message: "Unable to communicate with New Quizzes service" }] },
             status: :bad_gateway
      return
    end
    unless response.code == 200
      render json: { errors: [{ message: "New Quizzes service error" }] }, status: :bad_gateway
      return
    end

    body = parse_response_body(response)
    return render_service_error if body.nil?

    participants = body.is_a?(Array) ? body : (body["participants"] || body["accommodations"] || [])
    accommodations = extract_accommodations(participants)
    accommodation = accommodations.find { |a| a[:user_id].to_s == params[:user_id].to_s }
    if accommodation
      render json: { accommodation: }
    else
      render json: { errors: [{ message: "No accommodation found for user" }] }, status: :not_found
    end
  end

  private

  def require_assignment
    @assignment = @context.active_assignments.find(params[:assignment_id])
    unless @assignment.quiz_lti?
      render json: { errors: [{ message: "Assignment is not a New Quizzes assignment" }] },
             status: :unprocessable_entity
    end
  end

  def require_new_quizzes_service
    unless Services::NewQuizzes.api_gateway_host.present?
      render json: { errors: [{ message: "New Quizzes service is not configured" }] },
             status: :service_unavailable
    end
  end

  def parse_response_body(response)
    JSON.parse(response.body)
  rescue JSON::ParserError, TypeError => e
    Canvas::Errors.capture_exception(:new_quiz_accommodations, e, :warn)
    nil
  end

  def render_service_error
    render json: { errors: [{ message: "New Quizzes service error" }] }, status: :bad_gateway
  end

  def authorize_read
    render_unauthorized_action unless @context.grants_any_right?(@current_user, session, :manage_assignments, :manage_assignments_edit)
  end

  def extract_accommodations(participants)
    Array(participants).filter_map do |participant|
      next unless participant.is_a?(Hash)

      user_id = participant["user_id"] || participant["canvas_user_id"]
      next if user_id.nil?

      extra_time = participant["extra_time"] || participant["time_extension"]
      extra_attempts = participant["extra_attempts"]
      reduce_choices_enabled = participant["reduce_choices_enabled"]

      reduce_choices_enabled = Canvas::Plugin.value_to_boolean(reduce_choices_enabled)

      next unless extra_time.to_i > 0 || extra_attempts.to_i > 0 || reduce_choices_enabled

      {
        user_id:,
        extra_time:,
        extra_attempts:,
        reduce_choices_enabled:
      }
    end
  end

  def fetch_accommodations_from_service
    host = Services::NewQuizzes.api_gateway_host
    path = "/api/assignments/#{@assignment.id}/participants"
    url = "#{host}#{path}"

    token = CanvasSecurity::ServicesJwt.generate(
      {
        sub: @current_user.global_id.to_s,
        account_id: @context.root_account.global_id.to_s,
        course_id: @context.global_id.to_s
      },
      base64: false,
      encrypt: false
    )

    query = {}
    query[:page] = params[:page] if params[:page].present?

    Canvas.timeout_protection("new-quizzes-accommodations", raise_on_timeout: true) do
      HTTParty.get(url, headers: { "Authorization" => "Bearer #{token}" }, query:, timeout: 10)
    end
  rescue => e
    Canvas::Errors.capture_exception(:new_quiz_accommodations, e, :warn)
    nil
  end
end
