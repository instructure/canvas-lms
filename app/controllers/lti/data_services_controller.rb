#
# Copyright (C) 2019 - present Instructure, Inc.
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
  # @API Data Services
  # @internal
  #
  # Data service api for tools.
  #
  # @model DataServiceSubscription
  #     {
  #       "id": "DataServiceSubscription",
  #       "description": "A subscription to a data service live event.",
  #       "properties": {
  #          "ContextId": {
  #            "description": "The id of the context for the subscription.",
  #            "example": "8ADadf-asdfas-asdfas-asdfaew",
  #            "type": "string"
  #          },
  #          "ContextType": {
  #            "description": "The type of context for the subscription. Must be 'assignment', or 'root_account'",
  #            "example": "root_account",
  #            "type": "string"
  #          },
  #          "EventTypes": {
  #            "description": "Array of strings representing the event types for the subscription.",
  #            "example": ["asset_accessed"],
  #            "type": "array",
  #            "items": {"type": "string"}
  #          },
  #          "Format": {
  #            "description": "Format to deliver the live events. Must be 'live-event' or 'caliper'.",
  #            "example": "caliper",
  #            "type": "string"
  #          },
  #          "TransportMetadata": {
  #            "description": "An object with a single key: 'Url'.",
  #            "example": "{\n\t\"Url\":\"sqs.example\"}",
  #            "type": "string"
  #          },
  #          "TransportType": {
  #            "description": "The type of transport for the event. Must be either 'sqs' or 'https'.",
  #            "example": "sqs",
  #            "type": "string"
  #          }
  #       }
  #     }
  #
  #     @model DataServiceEventTypes
  #         {
  #            "id": "DataServiceEventTypes",
  #            "description": "A categorized list of all possible event types",
  #            "properties": {
  #               "EventCategory": {
  #                 "description": "An array of strings representing the event types in the category.",
  #                 "example": ["assignment_created"],
  #                 "type": "array",
  #                 "items": {"type": "string"}
  #               }
  #             }
  #         }
  #
  class DataServicesController < ApplicationController
    include Ims::Concerns::AdvantageServices
    MIME_TYPE = 'application/vnd.canvas.dataservices+json'.freeze

    ACTION_SCOPE_MATCHERS = {
      create: all_of(TokenScopes::LTI_CREATE_DATA_SERVICE_SUBSCRIPTION_SCOPE),
      show: all_of(TokenScopes::LTI_SHOW_DATA_SERVICE_SUBSCRIPTION_SCOPE),
      update: all_of(TokenScopes::LTI_UPDATE_DATA_SERVICE_SUBSCRIPTION_SCOPE),
      index: all_of(TokenScopes::LTI_LIST_DATA_SERVICE_SUBSCRIPTION_SCOPE),
      destroy: all_of(TokenScopes::LTI_DESTROY_DATA_SERVICE_SUBSCRIPTION_SCOPE),
      event_types_index: all_of(TokenScopes::LTI_LIST_EVENT_TYPES_DATA_SERVICE_SUBSCRIPTION_SCOPE)
    }.freeze.with_indifferent_access

    rescue_from Lti::SubscriptionsValidator::InvalidContextType do
      render json: {error: 'Invalid context type for subscription'}, status: :bad_request
    end

    rescue_from Lti::SubscriptionsValidator::ContextNotFound do
      render json: {error: 'Invalid context for subscription - context not found.'}, status: :bad_request
    end

    before_action :verify_service_configured

    # @API Create a Data Services Event Subscription
    # Creates a Data Service Event subscription for the specified event type and
    # context.
    #
    # @argument subscription[ContextId] [Required, String]
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
    #
    # @returns DataServiceSubscription
    def create
      sub = params.require(:subscription)
      SubscriptionsValidator.validate_subscription_context!(sub)
      response = Services::LiveEventsSubscriptionService.create(jwt_body, sub.to_unsafe_h)
      forward_service_response(response)
    end

    # @API Update a Data Services Event Subscription
    # Updates a Data Service Event subscription for the specified event type and
    # context.
    #
    # @argument subscription[ContextId] [Optional, String]
    #   The id of the context for the subscription.
    #
    # @argument subscription[ContextType] [Optional, String]
    #   The type of context for the subscription. Must be 'assignment',
    #   'account', or 'course'.
    #
    # @argument subscription[EventTypes] [Optional, Array]
    #   Array of strings representing the event types for
    #   the subscription.
    #
    # @argument subscription[Format] [Optional, String]
    #   Format to deliver the live events. Must be 'live-event' or 'caliper'.
    #
    # @argument subscription[TransportMetadata] [Optional, Object]
    #   An object with a single key: 'Url'. Example: { "Url": "sqs.example" }
    #
    # @argument subscription[TransportType] [Optional, String]
    #   Must be either 'sqs' or 'https'.
    # 
    # @argument subscription[State] [Optional, String]
    #   Must be either 'Active' or 'Deleted"
    #
    # @returns DataServiceSubscription
    def update
      sub = params.require(:subscription)
      SubscriptionsValidator.validate_subscription_context!(sub) if sub[:ContextType]
      updates = { 'Id': params[:id] }.merge(sub.to_unsafe_h)
      response = Services::LiveEventsSubscriptionService.update(jwt_body, updates)
      forward_service_response(response)
    end

    # @API Show a Data Services Event Subscription
    # Show existing Data Services Event Subscription
    #
    # @returns DataServiceSubscription
    def show
      response = Services::LiveEventsSubscriptionService.show(jwt_body, params.require(:id))
      forward_service_response(response)
    end

    # @API List all Data Services Event Subscriptions
    #
    # This endpoint returns a paginated list with a default limit of 100 items per result set.
    # You can retrieve the next result set by setting a 'StartKey' header in your next request
    # with the value of the 'EndKey' header in the response.
    #
    # Example use of a 'StartKey' header object:
    #   { "Id":"71d6dfba-0547-477d-b41d-db8cb528c6d1","OwnerId":"domain.instructure.com" }
    #
    # @returns DataServiceSubscription
    def index
      response = Services::LiveEventsSubscriptionService.index(jwt_body)
      forward_service_response(response)
    end


    # @API Destroy a Data Services Event Subscription
    # Destroy existing Data Services Event Subscription
    #
    # @returns DataServiceSubscription
    def destroy
      response = Services::LiveEventsSubscriptionService.destroy(jwt_body, params.require(:id))
      forward_service_response(response)
    end

    # @API List all event types in categories
    #
    # @returns DataServiceEventTypes
    def event_types_index
      response = Services::LiveEventsSubscriptionService.event_types_index(jwt_body, message_type)
      forward_service_response(response)
    end

    private

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end

    def verify_service_configured
      unless Services::LiveEventsSubscriptionService.available?
        render json: {error: 'Subscription service not configured'}, status: :internal_server_error
      end
    end

    def forward_service_response(service_response)
      render json: service_response.body, status: service_response.code, content_type: MIME_TYPE
    end

    def jwt_body
      dk_id = developer_key.global_id.to_s
      {
        sub: "#{dk_id}:#{context.uuid}",
        DeveloperKey: developer_key.global_id.to_s,
        RootAccountId: context.global_id,
        RootAccountUUID: context.uuid
      }
    end

    def context
      @context ||= Account.active.find_by(lti_context_id: params[:account_id])
    end

    def message_type
      params[:message_type] || 'live-event'
    end
  end
end
