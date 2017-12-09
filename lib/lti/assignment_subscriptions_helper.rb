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
  class AssignmentSubscriptionsHelper
    attr_accessor :assignment, :tool_proxy

    class AssignmentSubscriptionError < StandardError
    end

    SUBMISSION_EVENT_ID = 'vnd.Canvas.SubmissionEvent'.freeze
    EVENT_TYPES = %w(submission_created
                     plagiarism_resubmit
                     submission_updated
                     assignment_updated
                     assignment_created).freeze

    def initialize(tool_proxy, assignment = nil)
      @assignment = assignment
      @tool_proxy = tool_proxy
    end

    def create_subscription
      if Services::LiveEventsSubscriptionService.available? && assignment.present?
        subscription = assignment_subscription(assignment.global_id)
        result = Services::LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription)
        raise AssignmentSubscriptionError, error_message unless result.ok?
        result.parsed_response['Id']
      else
        raise AssignmentSubscriptionError, I18n.t('Live events subscriptions service is not configured')
      end
    end

    def assignment_subscription(context_id)
      {
        EventTypes: EVENT_TYPES,
        ContextType: 'assignment',
        ContextId: context_id.to_s,
        Format: format,
        TransportType: transport_type,
        TransportMetadata: transport_metadata
      }.with_indifferent_access
    end

    def destroy_subscription(subscription_id)
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
