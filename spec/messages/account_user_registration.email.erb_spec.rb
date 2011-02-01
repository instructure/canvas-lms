require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'account_user_registration.email' do
  it "should render" do
    @object = AccountUser.create(:account => account_model, :user => user_with_pseudonym)
    generate_message(:account_user_registration, :email, @object)
  end
end


# <% p = asset.is_a?(Pseudonym) ? asset : (asset.pseudonym || asset.user.pseudonym) %>
# <% define_content :link do %>
#   <% cc = asset.user.communication_channel %>http://<%= HostUrl.context_host(asset.account) %>/pseudonyms/<%= p.id %>/register/<%= cc.confirmation_code %>
# <% end %>
# 
# <% define_content :subject do %>
#   Canvas Account Admin Invitation
# <% end %>
# 
# You've been added as an <%= asset.readable_type %> to the account <%= asset.account.name %> at <%= HostUrl.context_host(asset.account) %>.  
# 
# <% email = asset.user.email; login = (asset.user.pseudonym.unique_id rescue "none") %>
# Name: <%= asset.user.name %>
# Email: <%= asset.user.email %>
# <% if email != login %>Username: <%= asset.user.pseudonym.unique_id rescue "none" %><% end %>
# 
# You'll need register with Canvas before you can participate as an account admin.  You can finish the registration process here:
# <%= content :link %>
# 
