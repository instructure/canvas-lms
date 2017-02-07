require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'report_generation_failed.email' do
  it "should render" do
    @object = Account.default.account_reports.create!(user: user_factory)
    @object.update_attribute :workflow_state, :error
    generate_message(:report_generation_failed, :email, @object)
  end
end
