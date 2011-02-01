require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'account_user_notification.email' do
  it "should render" do
    @object = AccountUser.create(:account => account_model)
    generate_message(:account_user_notification, :email, @object)
  end
end


# <% define_content :link do %>
#   http://<%= HostUrl.context_host(asset.account) %>/accounts/<%= asset.account_id %>
# <% end %>
# 
# <% define_content :subject do %>
#   Account Admin Notification
# <% end %>
# 
# You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>
# 
# Visit the account page here:
# <%= content :link %>
# 
