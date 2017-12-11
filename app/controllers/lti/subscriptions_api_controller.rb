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

module Lti
  # @API Webhooks Subscriptions
  # **LTI API for Webhook Subscriptions (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
  #
  # The tool proxy must also have the appropriate enabled capabilities (See appendix).
  #
  # Webhooks from Canvas are your way to know that a change (e.g. new or updated submission,
  # new or updated assignment, etc.) has taken place.
  #
  # Webhooks are available via HTTPS to an endpoint you own and specify, or via
  # an AWS SQS queue that you provision, own, and specify. We recommend SQS for
  # the most robust integration, but do support HTTPS for lower volume applications.
  #
  # We do not deduplicate or batch messages before transmission. Avoid
  # creating multiple identical subscriptions. Webhooks always identify the ID
  # of the subscription that caused them to be sent, allowing you to identify
  # problematic or high volume subscriptions.
  #
  # We cannot guarantee the transmission order of webhooks. If order is important
  # to your application, you must check the "event_time" attribute in the
  # "metadata" hash to determine sequence.
  class SubscriptionsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper

    WEBHOOK_SUBSCRIPTION_SERVICE = 'vnd.Canvas.webhooksSubscription'.freeze

    SERVICE_DEFINITIONS = [
      {
        id: WEBHOOK_SUBSCRIPTION_SERVICE,
        endpoint: 'api/lti/subscriptions',
        format: ['application/json'].freeze,
        action: ['POST', 'GET', 'PUT', 'DELETE'].freeze
      }.freeze
    ].freeze

    skip_before_action :load_user
    before_action :authorized_lti2_tool, :verify_service_configured

    rescue_from Lti::SubscriptionsValidator::InvalidContextType do
      render json: {error: 'Invalid subscription'}, status: :bad_request
    end

    rescue_from Lti::SubscriptionsValidator::MissingCapability,
                Lti::SubscriptionsValidator::ToolNotInContext do
        render json: {error: 'Unauthorized subscription'}, status: :unauthorized
    end

    def lti2_service_name
      WEBHOOK_SUBSCRIPTION_SERVICE
    end

    # @API Create a Webhook Subscription
    # Creates a webook subscription for the specified event type and
    # context.
    #
    # @argument submission[ContextId] [Required, String]
    #   The id of the context for the subscription.
    #
    # @argument subscription[ContextType] [Required, String]
    #   The type of context for the subscription. Must be 'assignment',
    #   'account', or 'course'.
    #
    # @argument subscription[EventTypes] [Required, Array]
    #   Array of strings representing the event types for
    #   the subscription.
    #
    # @argument subscription[Format] [Required, String]
    #   Format to deliver the live events. Must be 'live-event' or 'caliper'.
    #
    # @argument subscription[TransportMetadata] [Required, Object]
    #   An object with a single key: 'Url'. Example: { "Url": "sqs.example" }
    #
    # @argument subscription[TransportType] [Required, String]
    #   Must be either 'sqs' or 'https'.
    def create
      subscription_helper = SubscriptionsValidator.new(params.require(:subscription).to_unsafe_h, tool_proxy)
      subscription_helper.validate_subscription_request!
      response = Services::LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription_helper.subscription)
      forward_service_response(response)
    end

    # @API Delete a Webhook Subscription
    def destroy
      service_response = Services::LiveEventsSubscriptionService.destroy_tool_proxy_subscription(tool_proxy, params.require(:id))
      forward_service_response(service_response)
    end

    # @API Show a single Webhook Subscription
    def show
      service_response = Services::LiveEventsSubscriptionService.tool_proxy_subscription(tool_proxy, params.require(:id))
      forward_service_response(service_response)
    end

    # @API Update a Webhook Subscription
    # This endpoint uses the same parameters as the create endpoint
    def update
      subscription = params.require(:subscription)
      subscription['Id'] = params.require(:id)

      subscription_helper = SubscriptionsValidator.new(params.require(:subscription).to_unsafe_h, tool_proxy)
      subscription_helper.validate_subscription_request!

      service_response = Services::LiveEventsSubscriptionService.update_tool_proxy_subscription(tool_proxy, params.require(:id), subscription)
      forward_service_response(service_response)
    end


    # @API List all Webhook Subscription for a tool proxy
    #
    # This endpoint returns a paginated list with a default limit of 100 items per result set.
    # You can retrieve the next result set by setting a 'StartKey' header in your next request
    # with the value of the 'EndKey' header in the response.
    #
    # Example use of a 'StartKey' header object:
    #   { "Id":"71d6dfba-0547-477d-b41d-db8cb528c6d1","DeveloperKey":"10000000000001" }
    def index
      headers = request.headers['StartKey'] ? { 'StartKey' => request.headers['StartKey'] } : {}
      service_response = Services::LiveEventsSubscriptionService.tool_proxy_subscriptions(tool_proxy, headers)
      response.headers['EndKey'] = service_response.headers['endkey'] if service_response.headers['endkey']
      forward_service_response(service_response)
    end

    private

    def verify_service_configured
      unless Services::LiveEventsSubscriptionService.available?
        render json: {error: 'Subscription service not configured'}, status: :internal_server_error
      end
    end

    def forward_service_response(service_response)
      render json: service_response.body, status: service_response.code
    end

    # @!appendix Webhook Subscription Required Capabilities
    #
    #  {include:file:doc/api/subscriptions_appendix.md}
  end
end
