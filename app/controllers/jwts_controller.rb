# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API JWTs
# Short term tokens useful for talking to other services in the Canvas Ecosystem.
# Note: JWTs have no value or use directly against the Canvas API, and expire
# after one hour
#
# @model JWT
#    {
#      "id": "JWT",
#      "properties": {
#        "token": {
#           "description": "The signed, encrypted, base64 encoded JWT",
#           "example": "ZXlKaGJHY2lPaUprYVhJaUxDSmxibU1pT2lKQk1qVTJSME5OSW4wLi5QbnAzS1QzLUJkZ3lQZHgtLm5JT0pOV01iZmdtQ0g3WWtybjhLeHlMbW13cl9yZExXTXF3Y0IwbXkzZDd3V1NDd0JYQkV0UTRtTVNJSVRrX0FJcG0zSU1DeThMcW5NdzA0ckdHVTkweDB3MmNJbjdHeWxOUXdveU5ZZ3UwOEN4TkZteUpCeW5FVktrdU05QlRyZXZ3Y1ZTN2hvaC1WZHRqM19PR3duRm5yUVgwSFhFVFc4R28tUGxoQVUtUnhKT0pNakx1OUxYd2NDUzZsaW9ZMno5NVU3T0hLSGNpaDBmSGVjN2FzekVJT3g4NExUeHlReGxYU3BtbFZ5LVNuYWdfbVJUeU5yNHNsMmlDWFcwSzZCNDhpWHJ1clJVVm1LUkVlVTl4ZVVJcTJPaWNpSHpfemJ0X3FrMjhkdzRyajZXRnBHSlZPNWcwTlUzVHlSWk5qdHg1S2NrTjVSQjZ1X2FzWTBScjhTY2VhNFk3Y2JFX01wcm54cFZTNDFIekVVSVRNdzVMTk1GLVpQZy52LVVDTkVJYk8zQ09EVEhPRnFXLUFR",
#           "type": "string"
#         }
#       }
#    }
#

class JwtsController < ApplicationController
  before_action :require_user, :require_non_jwt_auth
  before_action :require_access_token, only: :create, if: :audience_requested?
  before_action :validate_requested_audience, only: :create, if: :audience_requested?
  before_action :require_authorized_context, only: :create, if: :workflows_require_context?

  # @API Create JWT
  #
  # Create a unique JWT for use with other Canvas services
  #
  # Generates a different JWT each time it's called. Each JWT expires
  # after a short window (1 hour)
  #
  # @argument workflows[] [String]
  #   Adds additional data to the JWT to be used by the consuming service workflow
  #
  # @argument context_type [Optional, String, "Course"|"User"|"Account"]
  #   The type of the context to generate the JWT for, in case the workflow requires it. Case insensitive.
  #
  # @argument context_id [Optional, Integer]
  #   The id of the context to generate the JWT for, in case the workflow requires it.
  #
  # @argument context_uuid [Optional, String]
  #   The uuid of the context to generate the JWT for, in case the workflow requires it. Note that context_id
  #   and context_uuid are mutually exclusive. If both are provided, an error will be returned.
  #
  # @argument canvas_audience [Optional, Boolean]
  #   Defaults to true. If false, the JWT will be signed, but not encrypted, for use in downstream services. The
  #   default encrypted behaviour can be used to talk to Canvas itself.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/jwts' \
  #         -X POST \
  #         -H "Accept: application/json" \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns JWT
  def create
    domain = request.host_with_port
    audience = requested_audience if audience_requested?

    services_jwt = CanvasSecurity::ServicesJwt.for_user(
      domain,
      @current_user,
      real_user: @real_current_user,
      workflows:,
      context:,
      symmetric: symmetric?,
      encrypt: encrypt?,
      audience:,
      root_account_uuid: @domain_root_account.uuid
    )
    render json: { token: services_jwt }
  end

  # @API Refresh JWT
  #
  # Refresh a JWT for use with other canvas services
  #
  # Generates a different JWT each time it's called, each one expires
  # after a short window (1 hour).
  #
  # @argument jwt [Required, String]
  #   An existing JWT token to be refreshed. The new token will have
  #   the same context and workflows as the existing token.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/jwts/refresh' \
  #         -X POST \
  #         -H "Accept: application/json" \
  #         -H 'Authorization: Bearer <token>'
  #         -d 'jwt=<jwt>'
  #
  # @returns JWT
  def refresh
    if params[:jwt].nil?
      return render(
        json: { errors: { jwt: "required" } },
        status: :bad_request
      )
    end

    user = @current_user
    real_user = @real_current_user

    if Account.site_admin.feature_enabled?(:new_quizzes_allow_service_jwt_refresh) && refresh_for_another_user?
      return render_invalid_refresh unless user_can_refresh?

      user = User.find(decrypted_jwt["sub"])
      real_user = decrypted_jwt["masq_sub"].present? ? User.find(decrypted_jwt["masq_sub"]) : nil
    end

    services_jwt = CanvasSecurity::ServicesJwt.refresh_for_user(
      params[:jwt],
      request.host_with_port,
      user,
      real_user:,
      # TODO: remove this once we teach all consumers to consume the asymmetric ones
      symmetric: true
    )
    render json: { token: services_jwt }
  rescue CanvasSecurity::ServicesJwt::InvalidRefresh, JSON::JWE::DecryptionFailed, JSON::JWT::InvalidFormat
    render_invalid_refresh
  end

  private

  def workflows_require_context?
    workflows.is_a?(Array) && workflows.any? { |workflow| CanvasSecurity::JWTWorkflow.workflow_requires_context?(workflow) }
  end

  def workflows
    params[:workflows]
  end

  def require_authorized_context
    context_type = params[:context_type]
    context_id = params[:context_id]
    context_uuid = params[:context_uuid]

    return render_error("Missing context_type parameter.") unless context_type.present?
    return render_error("Missing context_id or context_uuid parameter.") unless context_id.present? || context_uuid.present?
    return render_error("Should provide context_id or context_uuid parameters, but not both.") if context_id.present? && context_uuid.present?

    context_class = Course if context_type.casecmp?("Course")
    context_class = User if context_type.casecmp?("User")
    context_class = Account if context_type.casecmp?("Account")

    return render_error("Invalid context_type parameter.") unless context_class.present?

    @context = if context_id.present?
                 context_class.find(params[:context_id])
               else
                 context_class.find_by!(uuid: params[:context_uuid])
               end

    require_context_with_permission(@context, :read)
  end

  def decrypted_jwt
    @decrypted_jwt ||= CanvasSecurity::ServicesJwt.decrypt(CanvasSecurity.base64_decode(params[:jwt]), ignore_expiration: true)
  end

  def refresh_for_another_user?
    @current_user.global_id != decrypted_jwt["sub"].to_i
  end

  def user_can_refresh?
    @current_user.root_admin_for?(@domain_root_account) && @access_token.developer_key.internal_service?
  end

  def render_error(error_message, status = :bad_request)
    render json: { error: error_message }, status:
  end

  def render_unauthorized
    render(
      json: { errors: { jwt: "unauthorized" } },
      status: :unauthorized
    )
  end

  def render_invalid_refresh
    render(
      json: { errors: { jwt: "invalid refresh" } },
      status: :bad_request
    )
  end

  def render_not_allowed_audience
    render(
      json: {
        error: "invalid_target",
        error_description: "The requested audience is not permitted for this client"
      },
      status: :bad_request
    )
  end

  def encrypt?
    return false if audience_requested?

    params[:canvas_audience].nil? || value_to_boolean(params[:canvas_audience])
  end

  def symmetric?
    workflows.is_a?(Array) && workflows.any? { |workflow| CanvasSecurity::JWTWorkflow.workflow_requires_symmetric_encryption?(workflow) }
  end

  def audience_requested?
    !params[:audience].nil?
  end

  def require_access_token
    render_unauthorized unless @access_token
  end

  def validate_requested_audience
    render_not_allowed_audience unless valid_audience?
  end

  def requested_audience
    @requested_audience ||= params[:audience].split
  end

  def valid_audience?
    allowed_audiences = configured_audiences
    requested_audience.all? { |aud| allowed_audiences.include?(aud) }
  end

  def configured_audiences
    @access_token&.developer_key&.allowed_audiences || []
  end
end
