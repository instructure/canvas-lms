require File.expand_path(File.dirname(__FILE__) + "/common")

describe "web conference" do
  include_examples "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    PluginSetting.create!(:name => "wimba", :settings =>
        {"domain" => "wimba.instructure.com"})
  end

  context "with no conferences" do
    before (:each) do
      get "/courses/#{@course.id}/conferences"
    end

    it "should create a web conference" do
      conference_title = 'Testing Conference'
      keep_trying_until do
        expect(fj('.new-conference-btn')).to be_displayed
      end
      fj('.new-conference-btn').click
      wait_for_ajaximations
      keep_trying_until do
        replace_content(f('#web_conference_title'), conference_title)
        f('.ui-dialog .btn-primary').click
        wait_for_ajaximations
        expect(fj("#new-conference-list .ig-title")).to be_displayed
      end
      expect(fj("#new-conference-list .ig-title").text).to include(conference_title)
    end

    it "should cancel creating a web conference" do
      conference_title = 'new conference'
      f('.new-conference-btn').click
      wait_for_ajaximations
      keep_trying_until do
        replace_content(f('#web_conference_title'), conference_title)
        f('.ui-dialog button.cancel_button').click
        wait_for_ajaximations
      end
      expect(f('#add_conference_form')).not_to be_displayed
    end
  end

end
