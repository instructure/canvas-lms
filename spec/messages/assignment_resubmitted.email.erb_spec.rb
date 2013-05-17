require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'assignment_resubmitted.email' do
  it "should render" do
    @object = submission_model
    generate_message(:assignment_resubmitted, :email, @object)
  end
end


# <% define_content :link do %>
#   <%= HostUrl.protocol %>://<%= HostUrl.context_host(asset.assignment.context) %>/<%= asset.assignment.context.class.to_s.downcase.pluralize %>/<%= asset.assignment.context_id %>/assignments/<%= asset.assignment_id %>/submissions/<%= asset.user_id %>
# <% end %>
# 
# <% define_content :subject do %>
#   Re-Submission: <%= asset.user.name %>, <%= asset.assignment.title %>
# <% end %>
# 
# <%= asset.user.name %> has just turned in a re-submission for <%= asset.assignment.title %> in the course <%= asset.assignment.context.name %>. 
# 
# You can view the submission here: 
# <%= content :link %>
# 
