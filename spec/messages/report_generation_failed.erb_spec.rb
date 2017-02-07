require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'report_generation_failed' do
  before :once do
    @object = Account.default.account_reports.create!(user: user_factory)
    @object.update_attribute :workflow_state, :error
  end

  let(:asset) { @object }
  let(:notification_name) { :report_generation_failed }

  include_examples "a message"
end