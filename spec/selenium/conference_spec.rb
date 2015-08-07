require File.expand_path(File.dirname(__FILE__) + "/common")
require File.expand_path(File.dirname(__FILE__) + '/helpers/conferences_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "web conference" do
  include_context "in-process server selenium tests"
  let(:url) { "/courses/#{@course.id}/conferences" }

  context "with no conferences" do
    before(:each) do
      course_with_teacher_logged_in
      PluginSetting.create!(:name => "wimba", :settings =>
        {"domain" => "wimba.instructure.com"})
      get url
    end

    it "should display initial elements of the conference page", priority: "1", test_id: 118488 do
      keep_trying_until do
        expect(fj('.new-conference-btn')).to be_displayed
      end
      headers = ff('.element_toggler')
      expect(headers[0]).to include_text("New Conferences")
      expect(f('#new-conference-list')).to include_text("There are no new conferences")
      expect(headers[1]).to include_text("Concluded Conferences")
      expect(f('#concluded-conference-list')).to include_text("There are no concluded conferences")
    end

    it "should create a web conference", priority: "1", test_id: 118489 do
      conference_title = 'Testing Conference'
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

    it "should cancel creating a web conference", priority: "2" do
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

  context "with conferences" do
    before(:each) do
      course_with_teacher_logged_in
      PluginSetting.create!(:name => "wimba", :settings =>
        {"domain" => "wimba.instructure.com"})
      #Creates conferences before getting the page so they appear when it loads up
      @cc = WimbaConference.create!(:title => "test conference", :user => @user, :context => @course)
    end

    it "should delete active conferences", priority: "1", test_id: 126912 do
      get url

      f('.icon-settings').click
      wait_for_ajaximations
      delete_conference
      expect(f('#new-conference-list')).to include_text("There are no new conferences")
    end

    it "should delete concluded conferences", priority: "2", test_id: 163991 do
      #closing will conclude the conference
      @cc.close
      @cc.save!

      get url

      f('.icon-settings').click
      wait_for_ajaximations
      delete_conference
      expect(f('#concluded-conference-list')).to include_text("There are no concluded conferences")
    end

    context "Keyboard Accessibility" do
      it "should set focus to the preceding conference's cog when deleting" do
        @cc2 = WimbaConference.create!(:title => "test conference", :user => @user, :context => @course)
        get url

        settings_triggers = ff('.al-trigger')
        settings_triggers.last.click
        delete_conference
        check_element_has_focus(settings_triggers.first)
      end

      it "should set focus to the Add Conference button if there are no preceeding conferences" do
        get url

        settings_triggers = f('.al-trigger')
        settings_triggers.click
        delete_conference
        check_element_has_focus(f('.new-conference-btn'))
      end

      it "should set focus to the cog menu if the delete was cancelled" do
        get url

        f('.al-trigger').click
        f('.delete_conference_link').click
        driver.switch_to.alert.dismiss
        check_element_has_focus(f('.al-trigger'))
      end
    end
  end
end
