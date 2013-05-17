require File.expand_path(File.dirname(__FILE__) + "/common")

describe "web conference" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "dim_dim", :settings =>
        {"domain" => "dimdim.instructure.com"})
    get "/courses/#{@course.id}/conferences"
  end

  it "should create a web conference" do
    conference_title = 'Course Conference'
    f('.add_conference_link').click
    keep_trying_until do
      f('.communication_message .btn-primary').click
      wait_for_ajaximations
      fj(".title:contains('#{conference_title}')").displayed?
    end
    fj(".title:contains('#{conference_title}')").click
    f('#content').text.include?(conference_title).should be_true
  end

  it "should cancel creating a web conference" do
    conference_title = 'new conference'
    f('.add_conference_link').click
    replace_content(f('#web_conference_title'), conference_title)
    f('#add_conference_form button.cancel_button').click
    wait_for_animations
    f('#add_conference_form div.header').text.include?('Start').should be_false
  end
end
