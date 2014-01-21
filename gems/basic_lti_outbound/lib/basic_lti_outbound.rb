require 'uri'
require 'oauth'
require 'oauth/consumer'
require "i18n"

module BasicLtiOutbound
  require "basic_lti_outbound/lti_tool"
  require "basic_lti_outbound/lti_model"
  require "basic_lti_outbound/lti_context"
  require "basic_lti_outbound/lti_account"
  require "basic_lti_outbound/lti_course"
  require "basic_lti_outbound/lti_role"
  require "basic_lti_outbound/lti_user"
  require "basic_lti_outbound/lti_assignment"
  require "basic_lti_outbound/tool_launch"
  require "basic_lti_outbound/variable_substitutor"

  def self.generate(*args)
    BasicLtiOutbound::ToolLaunch.new(*args).generate
  end
end
