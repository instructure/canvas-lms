require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'assignment_submitted.facebook' do
  it "should render" do
    @object = submission_model
    generate_message(:assignment_submitted, :facebook, @object)
  end
end


# <% define_content :link do %>
#   <%= HostUrl.protocol %>://<%= HostUrl.context_host(asset.assignment.context) %>/<%= asset.assignment.context.class.to_s.downcase.pluralize %>/<%= asset.assignment.context_id %>/assignments/<%= asset.assignment_id %>/submissions/<%= asset.user_id %>
# <% end %>
# 
# <b><%= asset.user.name %></b> has just turned in a submission for <b><%= asset.assignment.title %></b> in the course <%= asset.assignment.context.name %>. 
# <br/><br/>
# <b><a href="<%= content :link %>">Click here to view the submission.</a></b>
