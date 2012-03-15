require File.expand_path(File.dirname(__FILE__) + '/common')

describe "chat" do
  it_should_behave_like "in-process server selenium tests"

  it "should render on the page correctly" do
    skip_if_ie("JavaScript error line 9")
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "tinychat", :settings => {})
    get "/courses/#{@course.id}/chat"
    driver.find_element(:css, ".tinychat_embed iframe").should be_displayed
  end
end

