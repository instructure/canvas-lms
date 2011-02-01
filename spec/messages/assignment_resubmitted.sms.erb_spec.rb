require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'assignment_resubmitted.sms' do
  it "should render" do
    @object = submission_model
    generate_message(:assignment_resubmitted, :sms, @object)
  end
end


# <%= asset.user.name %> just turned in their assignment (again), <%= asset.assignment.title %>
# 
# More info at <%= HostUrl.context_host(asset.assignment.context) %>
