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

require "json/jwt"

class Test::MockLtiController < ApplicationController
  skip_before_action :load_user
  skip_before_action :verify_authenticity_token

  # Defines a login endpoint for a mini LTI tool for testing purposes
  def login
    Rails.logger.info "[MockLTI] Login endpoint called - params: #{params.keys.join(", ")}"
    @client_id = DeveloperKey.last.global_id
    @redirect_uri = "http://#{HostUrl.default_host}/test/mock_lti/ui"
    @authorization_redirect = "http://#{HostUrl.default_host}/api/lti/authorize_redirect"
    @login_hint = params[:login_hint]
    @state = "asdf"
    @nonce = "jkl"
    @lti_message_hint = params[:lti_message_hint]

    render "login", layout: nil
  end

  # Endpoint for a minimal UI for an LTI tool. Shows a button that, when clicked,
  # will subscribe to the platform notification service.
  def ui
    Rails.logger.info "[MockLTI] UI endpoint called - JWT present: #{params[:id_token].present?}"
    id_token = params[:id_token]
    jwt = JWT.decode(id_token, nil, false) # false means don't bother verifying signature
    deep_link_settings = jwt.first["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"]
    deep_link_url = deep_link_settings&.dig("deep_link_return_url")
    deep_link_data = deep_link_settings&.dig("data")
    eula_url = jwt.first.dig("https://purl.imsglobal.org/spec/lti/claim/eulaservice", "url")
    notification_service_settings = jwt.first["https://purl.imsglobal.org/spec/lti/claim/platformnotificationservice"]
    notification_service_url = notification_service_settings&.dig("platform_notification_service_url")
    user_id = jwt.first["sub"] # The user's LTI ID

    # Build complete request specifications with all headers and bodies
    @requests = {
      pns_subscribe: {
        url: notification_service_url,
        method: "PUT",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{id_token}"
        },
        body: {
          handler: "http://#{HostUrl.default_host}/test/mock_lti/subscription_handler",
          notice_type: "LtiAssetProcessorSubmissionNotice"
        }
      },
      eula_service: {
        url: "#{eula_url}/user",
        method: "POST",
        headers: {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{id_token}"
        },
        body: {
          userId: user_id,
          accepted: true
          # timestamp will be added by client when button is clicked
        }
      },
      deep_link: {
        url: deep_link_url,
        method: "POST",
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded"
        },
        body: {
          JWT: create_deep_link_jwt(deep_link_data)
        },
        form_encoded: true # Signal to client this needs URLSearchParams
      }
    }

    render "ui", layout: nil
  end

  def subscription_handler
    render status: :ok
  end

  def jwks
    jwk = JSON::JWK.new(public_key)
    render(json: {
             keys: [jwk]
           })
  end

  def public_key
    private_key.public_key
  end

  def private_key
    OpenSSL::PKey::RSA.new 2048
  end

  def create_deep_link_jwt(data)
    content_item = {
      type: "ltiResourceLink",
      title: "Asset Processor",
      custom: {}
    }

    header = Base64.strict_encode64({ alg: "none", typ: "JWT" }.to_json).tr("+/", "-_").delete("=")
    payload = Base64.strict_encode64({
      "https://purl.imsglobal.org/spec/lti/claim/message_type" => "LtiDeepLinkingResponse",
      "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
      "https://purl.imsglobal.org/spec/lti-dl/claim/content_items" => [content_item],
      "https://purl.imsglobal.org/spec/lti-dl/claim/data" => data || ""
    }.to_json).tr("+/", "-_").delete("=")

    "#{header}.#{payload}."
  end
end
