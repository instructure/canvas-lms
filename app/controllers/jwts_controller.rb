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

  # @API Create JWT
  #
  # Create a unique jwt for using with other Canvas services
  #
  # Generates a different JWT each time it's called, each one expires
  # after a short window (1 hour)
  #
  # @argument workflows[] [String]
  #   Adds additional data to the JWT to be used by the consuming service workflow
  #
  # @argument context_type [Optional, String, "Course"|"User"|"Account"]
  #   The type of the context in case a specified workflow uses it to consuming the service. Case insensitive.
  #
  # @argument context_id [Optional, Integer]
  #   The id of the context in case a specified workflow uses it to consuming the service.
  #
  # @argument context_uuid [Optional, String]
  #   The uuid of the context in case a specified workflow uses it to consuming the service.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/jwts' \
  #         -X POST \
  #         -H "Accept: application/json" \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns JWT
  def create
    workflows = params[:workflows]
    if workflows_require_context?(workflows)
      init_context
      return render json: { error: @error }, status: :bad_request if @error
      return render json: { error: "Context not found." }, status: :not_found unless @context
      return unless authorized_action(@context, @current_user, :read)
    end
    # TODO: remove this once we teach all consumers to consume the asymmetric ones
    symmetric = workflows_require_symmetric_encryption?(workflows)
    domain = request.host_with_port
    services_jwt = CanvasSecurity::ServicesJwt.for_user(
      domain,
      @current_user,
      real_user: @real_current_user,
      workflows:,
      context: @context,
      symmetric:
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

  def workflows_require_context?(workflows)
    workflows.is_a?(Array) && workflows.include?("rich_content")
  end

  def workflows_require_symmetric_encryption?(workflows)
    # TODO: remove this once we teach the rcs to consume the asymmetric ones
    workflows.is_a?(Array) && workflows.include?("rich_content")
  end

  def init_context
    context_type = params[:context_type]
    context_id = params[:context_id]
    context_uuid = params[:context_uuid]

    return @error = "Missing context_type parameter." unless context_type.present?
    return @error = "Missing context_id or context_uuid parameter." unless context_id.present? || context_uuid.present?
    return @error = "Should provide context_id or context_uuid parameters, but not both." if context_id.present? && context_uuid.present?

    context_class = Course if context_type.casecmp("Course").zero?
    context_class = User if context_type.casecmp("User").zero?
    context_class = Account if context_type.casecmp("Account").zero?
    return @error = "Invalid context_type parameter." if context_class.nil?

    begin
      @context = if context_id.present?
                   context_class.find(params[:context_id])
                 else
                   context_class.find_by(uuid: params[:context_uuid])
                 end
    rescue ActiveRecord::RecordNotFound
      @context = nil
    end
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

  def render_invalid_refresh
    render(
      json: { errors: { jwt: "invalid refresh" } },
      status: :bad_request
    )
  end
end
