module Lti
  class LtiToolCreator
    PRIVACY_LEVEL_MAP = {
        'public' => LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC,
        'email_only' => LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY,
        'name_only' => LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY,
        'anonymous' => LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
    }
    def initialize(context_external_tool)
      @context_external_tool = context_external_tool
    end

    def convert()
      LtiOutbound::LTITool.new.tap do |lti_tool|
        lti_tool.name = @context_external_tool.name
        lti_tool.consumer_key = @context_external_tool.consumer_key
        lti_tool.shared_secret = @context_external_tool.shared_secret
        lti_tool.settings = @context_external_tool.settings

        lti_tool.privacy_level = PRIVACY_LEVEL_MAP[@context_external_tool.privacy_level] || LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      end
    end
  end
end