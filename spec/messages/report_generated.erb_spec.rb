require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'report_generated' do
  before :once do
    @object = Account.default.account_reports.create!(user: user_factory)
    @object.attachment = attachment_model
    @object.update_attribute :workflow_state, :complete
  end

  let(:asset) { @object }
  let(:notification_name) { :report_generated }

  include_examples "a message"
end