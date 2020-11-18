# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
  class PlagiarismSubscriptionsHelper
    attr_accessor :tool_proxy, :product_family

    class PlagiarismSubscriptionError < StandardError
    end

    SUBMISSION_EVENT_ID = 'vnd.Canvas.SubmissionEvent'.freeze
    EVENT_TYPES = %w(submission_created
                     plagiarism_resubmit
                     submission_updated
                     assignment_updated
                     assignment_created).freeze

    def initialize(tool_proxy)
      @tool_proxy = tool_proxy
      @product_family = tool_proxy.product_family
    end

    def create_subscription
      Rails.logger.info { "in: PlagiarismSubscriptionsHelper::create_subscription, tool_proxy_id: #{tool_proxy.id}" }
      if Services::LiveEventsSubscriptionService.available?
        subscription = plagiarism_subscription(tool_proxy, product_family)
        result = Services::LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription)
        raise PlagiarismSubscriptionError, error_message unless result.ok?
        result.parsed_response['Id']
      else
        raise PlagiarismSubscriptionError, I18n.t('Live events subscriptions service is not configured')
      end
    end

    def plagiarism_subscription(tool_proxy, product_family)
      enabled = Account.site_admin.feature_enabled?(:system_and_user_generated_event_types)
      sub = {
        EventTypes: EVENT_TYPES,
        ContextType: 'root_account',
        ContextId: tool_proxy.context.root_account.uuid,
        Format: format,
        TransportType: transport_type,
        TransportMetadata: transport_metadata,
        AssociatedIntegrationId: [product_family.vendor_code, product_family.product_code, tool_proxy.event_endpoint].join('_')
      }.with_indifferent_access
      sub[:SystemEventTypes] = EVENT_TYPES if enabled
      sub[:UserEventTypes] = EVENT_TYPES if enabled
      sub
    end

    def destroy_subscription(subscription_id)
      Rails.logger.info { "in: PlagiarismSubscriptionsHelper::destroy_subscription, subscription_id: #{subscription_id}" }
      if Services::LiveEventsSubscriptionService.available?
        Services::LiveEventsSubscriptionService.destroy_tool_proxy_subscription(tool_proxy, subscription_id)
      end
    end

    private

    def error_message
      if submission_event_service.blank?
        I18n.t('Plagiarism review tool is missing submission event service')
      elsif submission_event_service.endpoint.blank?
        I18n.t('Plagiarism review tool submission event service is missing endpoint')
      else
        I18n.t('Plagiarism review tool error')
      end
    end

    def submission_event_service
      @_submission_event_service ||= begin
        tool_proxy.find_service(SUBMISSION_EVENT_ID, 'POST')
      end
    end

    def format
      'live-event'
    end

    def transport_type
      'https'
    end

    def transport_metadata
      {'Url': submission_event_service&.endpoint}
    end
  end
end
