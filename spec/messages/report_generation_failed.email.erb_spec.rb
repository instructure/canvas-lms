require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'report_generation_failed.email' do
  it "should render" do
    @object = Account.default.account_reports.create!(user: user)
    @object.update_attribute :workflow_state, :error
    generate_message(:report_generation_failed, :email, @object)
  end
end


# <% define_content :link do %>
#   <%= HostUrl.protocol %>://<%= HostUrl.context_host(asset.context) %>/accounts/<%= asset.account_id %>/files/<%= asset.attachment_id %>/download
# <% end %>
#   
# <% define_content :subject do %>
#   Report Generation Failed
# <% end %>
# 
# <%= asset.message %>
# 
