module Lti
  class AssignmentSubscriptionsHelper
    attr_accessor :assignment, :tool_proxy

    class AssignmentSubscriptionError < StandardError
    end

    SUBMISSION_EVENT_ID = 'SubmissionEvent'.freeze

    def initialize(assignment, tool_proxy)
      @assignment = assignment
      @tool_proxy = tool_proxy
    end

    def create_subscription
      if Services::LiveEventsSubscriptionService.available?
        subscription = assignment_subscription(assignment.global_id)
        result = Services::LiveEventsSubscriptionService.create_tool_proxy_subscription(tool_proxy, subscription)
        raise AssignmentSubscriptionError, error_message unless result.ok?
        result.parsed_response['Id']
      end
    end

    def assignment_subscription(context_id)
      {
        EventTypes: ['submission_created'],
        ContextType: 'assignment',
        ContextId: context_id.to_s,
        Format: format,
        TransportType: transport_type,
        TransportMetadata: transport_metadata
      }.with_indifferent_access
    end

    private

    def error_message
      if submission_event_service.blank?
        I18n.t('Plagiarism review tool is missing submission event service')
      elsif submission_event_service&.endpoint.blank?
        I18n.t('Plagiarism review tool submission event service is missing endpoint')
      else
        I18n.t('Plagiarism review tool error')
      end
    end

    def submission_event_service
      @_submission_event_service ||= begin
        tp = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
        tp.tool_profile&.service_offered&.find do |s|
          s.id.include?(SUBMISSION_EVENT_ID) && s.action.include?("POST")
        end
      end
    end

    def format
      'caliper'
    end

    def transport_type
      'https'
    end

    def transport_metadata
      {'Url': submission_event_service&.endpoint}
    end
  end
end
