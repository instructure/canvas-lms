module Lti
  class CapabilitiesHelper
    attr_accessor :context
    def initialize(context)
      @context = context
    end

    def parameter_capabilities_hash
      @_param_capabilities_hash ||= begin
        recommended_params.merge optional_params
      end
    end

    def parameter_capabilities
      parameter_capabilities_hash.keys
    end

    def recommended_params
      {
        'launch_presentation_document_target' => IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME,
        'tool_consumer_instance_guid' => tc_instance_guid
      }
    end

    def optional_params
      {
        'launch_presentation_locale' => I18n.locale || I18n.default_locale.to_s
      }
    end

    private

    def tc_instance_guid
      if context.respond_to?(:root_account) && context.root_account.present?
        context.root_account.lti_guid
      end
    end

  end
end
