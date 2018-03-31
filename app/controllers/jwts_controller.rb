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
  # Create a unique jwt for using with other canvas services
  #
  # Generates a different JWT each time it's called, each one expires
  # after a short window (1 hour)
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/jwts' \
  #         -X POST \
  #         -H "Accept: application/json" \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns JWT
  def create
    services_jwt = Canvas::Security::ServicesJwt.
      for_user(request.env['HTTP_HOST'], @current_user, real_user: @real_current_user)
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
        json: {errors: {jwt: "required"}},
        status: 400
      )
    end
    services_jwt = Canvas::Security::ServicesJwt.refresh_for_user(
      params[:jwt],
      request.env['HTTP_HOST'],
      @current_user,
      real_user: @real_current_user
    )
    render json: { token: services_jwt }
  rescue Canvas::Security::ServicesJwt::InvalidRefresh
    render(
      json: {errors: {jwt: "invalid refresh"}},
      status: 400
    )
  end

  private

  def require_non_jwt_auth
    if @authenticated_with_jwt
      render(
        json: {error: "cannot generate a JWT when authorized by a JWT"},
        status: 403
      )
    end
  end

end
