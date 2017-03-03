module ExternalToolsSpecHelper
  # Public: Create a new valid LTI tool for the given course.
  #
  # course - The course to create the tool for.
  #
  # Returns a valid ExternalTool.
  def new_valid_tool(course)
    tool = course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
    )
    tool.url = "http://www.example.com/basic_lti"
    tool.resource_selection = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :selection_width => 400,
      :selection_height => 400}
    tool.save!
    tool
  end
end
