require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'report_generated.email' do
  it "should render" do
    @object = AccountReport.create!
    @object.update_attribute :workflow_state, :complete
    generate_message(:report_generated, :email, @object)
  end
end


# <% define_content :link do %>
#   <%= HostUrl.protocol %>://<%= HostUrl.context_host(asset.context) %>/accounts/<%= asset.account_id %>/files/<%= asset.attachment_id %>/download
# <% end %>
#   
# <% define_content :subject do %>
#   Report Generated
# <% end %>
# 
# <%= asset.message %>
# 
# 
# Click here to download the report: 
# <%= content :link %>
