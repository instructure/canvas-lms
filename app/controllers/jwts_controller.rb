# @API JWTs
# @beta
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

  before_action :require_user

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
  def create
    if @authenticated_with_jwt
      render(
        json: {error: "cannot generate a JWT when authorized by a JWT"},
        status: 403
      )
      return false
    end
    services_jwt = Canvas::Security::ServicesJwt.
      for_user(request.env['HTTP_HOST'], @current_user, real_user: @real_current_user)
    render json: { token: services_jwt }
  end

end
