require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

RSpec.shared_context "lti2_spec_helper", :shared_context => :metadata do

  let(:account) { Account.new }
  let(:developer_key) {DeveloperKey.create!(redirect_uri: 'http://www.example.com/redirect')}
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: '123',
      product_code: 'abc',
      vendor_name: 'acme',
      root_account: account,
      developer_key: developer_key
    )
  end
  let(:tool_proxy) do
    Lti::ToolProxy.create!(
      context: account,
      guid: SecureRandom.uuid,
      shared_secret: 'abc',
      product_family: product_family,
      product_version: '1',
      workflow_state: 'active',
      raw_data: {'enabled_capability' => ['Security.splitSecret']},
      lti_version: '1'
    )
  end
  let(:resource_handler) do
    Lti::ResourceHandler.create!(
      resource_type_code: 'code',
      name: 'resource name',
      tool_proxy: tool_proxy
    )
  end
  let(:message_handler) do
    Lti::MessageHandler.create!(
      message_type: 'message_type',
      launch_path: 'https://samplelaunch/blti',
      resource_handler: resource_handler
    )
  end


end
