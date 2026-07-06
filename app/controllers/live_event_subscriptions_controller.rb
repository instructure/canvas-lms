# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# @API Live Event Subscriptions
#
# Read-only API for auditing Live Event subscriptions configured for an account.
# Subscriptions define which Canvas events are forwarded to external consumers
# (e.g., via SQS or HTTPS) and in which format (live-event or caliper).
#
# Sensitive fields such as AWS keys and secrets are masked in the response.
#
# @model LiveEventSubscription
#    {
#      "id": "LiveEventSubscription",
#      "description": "A Live Event subscription that forwards Canvas events to an external endpoint.",
#      "properties": {
#        "Id": {
#          "description": "The unique identifier for the subscription.",
#          "example": "71d6dfba-0547-477d-b41d-db8cb528c6d1",
#          "type": "string"
#        },
#        "ContextId": {
#          "description": "The id of the context (account) for this subscription.",
#          "example": "10000000000001",
#          "type": "string"
#        },
#        "ContextType": {
#          "description": "The type of context. Typically 'root_account'.",
#          "example": "root_account",
#          "type": "string"
#        },
#        "EventTypes": {
#          "description": "Array of event type names this subscription listens for.",
#          "example": ["course_created", "enrollment_created"],
#          "type": "array",
#          "items": { "type": "string" }
#        },
#        "Format": {
#          "description": "Delivery format. Either 'live-event' or 'caliper'.",
#          "example": "live-event",
#          "type": "string"
#        },
#        "TransportType": {
#          "description": "Transport mechanism. Either 'sqs' or 'https'.",
#          "example": "sqs",
#          "type": "string"
#        },
#        "TransportMetadata": {
#          "description": "Transport configuration. Sensitive values are masked.",
#          "example": { "Url": "https://sqs.us-east-1.amazonaws.com/123456789012/my-queue" },
#          "type": "object"
#        },
#        "State": {
#          "description": "The state of the subscription.",
#          "example": "Active",
#          "type": "string"
#        }
#      }
#    }
class LiveEventSubscriptionsController < ApplicationController
  before_action :require_account_context
  before_action { require_feature_enabled :live_event_subscriptions_api }
  before_action :require_root_account
  before_action :require_manage_data_services
  before_action :verify_service_configured

  SENSITIVE_KEY_PATTERN = /(?:_|\b)(?:key|secret|credential|token|password)(?:_|\b)/i

  # @API List Live Event Subscriptions
  #
  # Returns all live event subscriptions for the specified root account.
  # Must be called on a root account. Sub-accounts are not currently
  # supported (the account_id parameter is preserved for future use).
  #
  # Sensitive fields (AWS keys, secrets, etc.) are masked in the response.
  #
  # @returns [LiveEventSubscription]
  def index
    response = Services::LiveEventsSubscriptionService.index(jwt_body)
    render_masked_response(response)
  rescue StandardError => e
    handle_service_error(e)
  end

  # @API Show a Live Event Subscription
  #
  # Returns a single live event subscription by ID.
  #
  # Sensitive fields (AWS keys, secrets, etc.) are masked in the response.
  #
  # @returns LiveEventSubscription
  def show
    response = Services::LiveEventsSubscriptionService.show(jwt_body, params.require(:id))
    render_masked_response(response)
  rescue StandardError => e
    handle_service_error(e)
  end

  private

  def require_root_account
    return if @context.root_account?

    render json: { error: "Live event subscriptions are only available for root accounts" },
           status: :bad_request
  end

  def jwt_body
    {
      sub: "#{@context.global_id}:#{@context.uuid}",
      DeveloperKey: "internal",
      RootAccountId: @context.global_id,
      RootAccountUUID: @context.uuid
    }
  end

  def require_manage_data_services
    authorized_action(@context, @current_user, :manage_data_services)
  end

  def verify_service_configured
    return if Services::LiveEventsSubscriptionService.available?

    render json: { error: "Live Events Subscription service not configured" },
           status: :service_unavailable
  end

  def handle_service_error(error)
    Canvas::Errors.capture_exception(:live_event_subscriptions, error, :warn)
    render json: { error: "Unable to communicate with Live Events Subscription service" },
           status: :bad_gateway
  end

  def render_masked_response(service_response)
    body = JSON.parse(service_response.body)
    masked = mask_sensitive_fields(body)
    render json: masked, status: service_response.code
  rescue JSON::ParserError
    render json: { error: "Unexpected response from subscription service" },
           status: :bad_gateway
  end

  def mask_sensitive_fields(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(key, value), result|
        result[key] = if sensitive_key?(key)
                        mask_value(value)
                      elsif value.is_a?(String) && url_like?(value)
                        mask_url(value)
                      else
                        mask_sensitive_fields(value)
                      end
      end
    when Array
      obj.map { |item| mask_sensitive_fields(item) }
    else
      obj
    end
  end

  def sensitive_key?(key)
    SENSITIVE_KEY_PATTERN.match?(key.to_s)
  end

  def url_like?(value)
    value.match?(%r{\Ahttps?://}i)
  end

  def mask_url(url)
    uri = URI.parse(url)

    if uri.userinfo
      uri.user = mask_string(uri.user) if uri.user
      uri.password = mask_string(uri.password) if uri.password
    end

    if uri.query
      masked_params = URI.decode_www_form(uri.query).map do |key, value|
        [key, mask_string(value)]
      end
      uri.query = URI.encode_www_form(masked_params)
    end

    uri.to_s
  rescue URI::InvalidURIError, ArgumentError
    mask_string(url)
  end

  def mask_value(value)
    case value
    when String
      mask_string(value)
    when Hash
      value.transform_values { |v| mask_value(v) }
    when Array
      value.map { |v| mask_value(v) }
    else
      value
    end
  end

  def mask_string(str)
    return str if str.nil? || str.length <= 4

    "#{str[0..1]}******#{str[-2..]}"
  end
end
