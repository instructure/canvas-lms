require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'assignment_submitted.summary' do
  it "should render" do
    @object = submission_model
    generate_message(:assignment_submitted, :summary, @object)
  end
end


# <% define_content :link do %>
#   <%= HostUrl.protocol %>://<%= HostUrl.context_host(asset.assignment.context) %>/<%= asset.assignment.context.class.to_s.downcase.pluralize %>/<%= asset.assignment.context_id %>/assignments/<%= asset.assignment_id %>/submissions/<%= asset.user_id %>
# <% end %>
# 
# <% define_content :subject do %>
#   Submission: <%= asset.user.name %>, <%= asset.assignment.title %>
# <% end %>
# turned in: <%= force_zone(asset.submitted_at).strftime("%b %d at %I:%M") rescue "" %><%= force_zone(asset.submitted_at).strftime("%p").downcase rescue "" %>
# 
