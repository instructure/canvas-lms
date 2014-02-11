module Lti
  class LtiOutboundAdapter
    def initialize(url, tool, user, context, link_code, return_url, resource_type)
      @url = url
      @tool = tool
      @user = user
      @context = context
      @link_code = link_code
      @return_url = return_url
      @resource_type = resource_type
      @outgoing_email_address = HostUrl.outgoing_email_address
      @root_account = context.root_account || tool.context.root_account || raise('Root account required for generating LTI content')

      @hash = {}
    end

    def generate_post_payload
      lti_context = Lti::LtiContextCreator.new(@context, @tool).convert
      lti_user = Lti::LtiUserCreator.new(@user, @root_account, @tool, @context).convert
      lti_tool = Lti::LtiToolCreator.new(@tool).convert

      LtiOutbound::ToolLaunch.new({
                                      url: @url,
                                      link_code: @link_code,
                                      return_url: @return_url,
                                      resource_type: @resource_type,
                                      outgoing_email_address: @outgoing_email_address,
                                      context: lti_context,
                                      user: lti_user,
                                      tool: lti_tool
                                  }).generate
    end
  end
end