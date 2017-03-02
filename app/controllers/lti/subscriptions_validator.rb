module Lti
  class SubscriptionsValidator
    class InvalidContextType < StandardError
    end
    class MissingCapability < StandardError
    end
    class ToolNotInContext < StandardError
    end

    CONTEXT_WHITELIST = [Course, Account, Assignment].freeze

    attr_reader :subscription, :tool_proxy

    def initialize(subscription, tool_proxy)
      @subscription = subscription.with_indifferent_access
      @tool_proxy = tool_proxy
    end

    def check_required_capabilities!
      capabilities_hash = ToolConsumerProfile.webhook_subscription_capabilities
      return if tool_webhook_capabilities.include?(ToolConsumerProfile.webhook_grant_all_capability)

      subscription[:EventTypes].each do |event_type|
        raise MissingCapability, "EventType #{event_type} is invalid" unless capabilities_hash.keys.include?(event_type.to_sym)
        if (tool_webhook_capabilities & capabilities_hash[event_type.to_sym]).blank?
          raise MissingCapability, 'Missing required capability'
        end
      end
    end

    def check_tool_context!
      requested_context = subscription_context
      requested_context = requested_context.course if requested_context.respond_to?(:course)
      raise ToolNotInContext, "Tool does not have access to requested context" unless tool_proxy.active_in_context?(requested_context)
    end

    def validate_subscription_request!
      check_required_capabilities!
      check_tool_context!
    end

    private

    def tool_webhook_capabilities
      ims_tool_proxy = IMS::LTI::Models::ToolProxy.from_json(tool_proxy.raw_data)
      ims_tool_proxy.enabled_capabilities
    end

    def subscription_context
      @_subscription_context ||= begin
        model = subscription[:ContextType].titlecase.constantize
        raise InvalidContextType unless CONTEXT_WHITELIST.include?(model)
        model.find(subscription[:ContextId].to_i)
      end
    rescue NameError
      raise InvalidContextType, "ContextType is invalid"
    end
  end
end
