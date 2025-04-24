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

module CaptchaValidation
  private

  def validate_captcha
    return unless captcha_server_key.present? # Don't be broken if captcha isn't configured in this environment
    return if logged_in_user # Skip for authenticated users

    form_data = { secret: captcha_server_key, response: params["g-recaptcha-response"] }
    http_response = CanvasHttp.post("https://www.google.com/recaptcha/api/siteverify", form_data:)

    if http_response && http_response.code == "200"
      parsed = JSON.parse(http_response.body)
      return parsed["error-codes"] unless parsed["success"]
      return ["invalid-hostname"] unless parsed["hostname"] == request.host

      nil
    else
      raise "Failed to connect to captcha service: #{http_response}"
    end
  end

  def validate_captcha!
    errors = validate_captcha
    return unless errors

    respond_to do |format|
      format.html do
        flash[:error] = t "Try again"
        redirect_back fallback_location: root_url
      end
      format.json do
        render json: { errors: }, status: :bad_request
      end
    end
  end

  def captcha_server_key
    DynamicSettings.find(tree: :private)["recaptcha_server_key"]
  end
end
