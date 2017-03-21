require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require 'spec_helper'

describe DataFixup::AddToolProxyToMessageHandler do
  include_context 'lti2_spec_helper'

  it "sets message handlers' 'tool_proxy' to the resource handler tool proxy" do
    message_handler.update_attribute(:tool_proxy, nil)
    DataFixup::AddToolProxyToMessageHandler.run
    expect(Lti::MessageHandler.last.tool_proxy).to eq tool_proxy
  end
end
