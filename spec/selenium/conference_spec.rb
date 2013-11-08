require File.expand_path(File.dirname(__FILE__) + "/common")

describe "web conference" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "wimba", :settings =>
        {"domain" => "wimba.instructure.com"})
  end

  context "with no conferences" do
    before (:each) do
      get "/courses/#{@course.id}/conferences"
      wait_for_ajaximations
    end

    it "should create a web conference" do
      conference_title = 'Testing Conference'
      keep_trying_until do
        fj('.new-conference-btn').should be_displayed
      end
      fj('.new-conference-btn').click
      wait_for_ajaximations
      keep_trying_until do
        replace_content(f('#web_conference_title'), conference_title)
        f('#add_conference_form .btn-primary').click
        wait_for_ajaximations
        fj("#new-conference-list .ig-title").should be_displayed
      end
      fj("#new-conference-list .ig-title").text.should contain(conference_title)
    end

    it "should cancel creating a web conference" do
      conference_title = 'new conference'
      f('.new-conference-btn').click
      wait_for_ajaximations
      keep_trying_until do
        replace_content(f('#web_conference_title'), conference_title)
        f('#add_conference_form button.cancel_button').click
        wait_for_ajaximations
      end
      f('#add_conference_form').should_not be_displayed
    end
  end

end
