require File.expand_path(File.dirname(__FILE__) + '/common')

describe "chat" do
  it_should_behave_like "in-process server selenium tests"

  it "should render on the page correctly" do
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "tinychat", :settings => {})
    get "/courses/#{@course.id}/chat"
    keep_trying_until { f(".tinychat_embed iframe").should be_displayed }
  end
end

