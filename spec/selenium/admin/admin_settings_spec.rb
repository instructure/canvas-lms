require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/external_tools_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "settings tabs" do
  def date_chooser(date = "n")
    today = f(".ui-datepicker-calendar .ui-state-highlight").text.to_i
    days = ff("#ui-datepicker-div .ui-state-default").count
    time= Time.now
    if (date == "t")
      if (today == days)
        ff("#ui-datepicker-div .ui-icon")[1].click
        ff("#ui-datepicker-div .ui-state-default")[0].click
      else
        ff("#ui-datepicker-div .ui-state-default")[today].click
      end
      time = time + 86400
    else
      f(".ui-datepicker-calendar .ui-state-highlight").click
    end
    f("#ui-datepicker-div button[type='button']").click
    time.strftime("%Y-%m-%d")
  end

  def add_announcement
    f("#tab-announcements-link").click
    fj(".element_toggler:visible").click
    subject = "This is a date change"
    f("#account_notification_subject").send_keys(subject)
    f("#account_notification_icon .calendar").click
    ff("#add_notification_form .ui-datepicker-trigger")[0].click
    today = date_chooser
    ff("#add_notification_form .ui-datepicker-trigger")[1].click
    tomorrow = date_chooser("t")
    type_in_tiny "textarea", "this is a message"
    yield if block_given?
    submit_form("#add_notification_form")
    wait_for_ajax_requests
    notification = AccountNotification.first
    notification.message.should include_text("this is a message")
    notification.subject.should include_text(subject)
    notification.start_at.to_s.should include_text today
    notification.end_at.to_s.should include_text tomorrow
    f("#tab-announcements .user_content").text.should == "this is a message"
    notification
  end

  describe "site admin" do
    include_examples "external tools tests"
    before(:each) do
      # course_with_
      site_admin_logged_in
      get "/accounts/#{Account.site_admin.id}/settings"
    end

    #context "announcements tab" do
    #  it "should require confirmation" do
    #    add_announcement do
    #      submit_form("#add_notification_form")
    #      ff('.error_box').last.text.should =~ /You must confirm/
    #      wait_for_ajax_requests
    #      AccountNotification.count.should == 0
    #      f("#confirm_global_announcement").click
    #    end
    #  end
    #
    #  it "should create survey announcements" do
    #    notification = add_announcement do
    #      f("#account_notification_required_account_service").click
    #      get_value("#account_notification_months_in_display_cycle").should == AccountNotification.default_months_in_display_cycle.to_s
    #      set_value(f("#account_notification_months_in_display_cycle"), "12")
    #    end
    #    notification.required_account_service.should == "account_survey_notifications"
    #    notification.months_in_display_cycle.should == 12
    #  end
    #end
  end

  describe "admin" do
    include_examples "external tools tests"
    before(:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}/settings"
    end

    context "external tools tab" do
      before(:each) do
        f("#tab-tools-link").click
      end

      it "should add a manual external tool" do
        add_external_tool
      end

      it "should add a manual external tool with an url and a work-flow state of public " do
        add_external_tool :manual_url, :public
      end

      it "should add a manual external tool with work-flow state of name_only " do
        add_external_tool :name_only
      end

      it "should add xml external tool" do
        add_external_tool :xml
      end

      it "should add url external tool" do
        mocked_bti_response = {
          :description          => "Search publicly available YouTube videos. A new icon will show up in your course rich editor letting you search YouTube and click to embed videos in your course material.",
          :title                => "YouTube",
          :url                  => "http://www.edu-apps.org/tool_redirect?id=youtube",
          :custom_fields        => {},
          :extensions           => [],
          :privacy_level        => "anonymous",
          :domain               => nil,
          :consumer_key         => nil,
          :shared_secret        => nil,
          :tool_id              => "youtube",
          :assignment_points_possible => nil,
          :settings => {
            :editor_button => {
              :url              => "http://www.edu-apps.org/tool_redirect?id=youtube",
              :icon_url         => "http://www.edu-apps.org/tools/youtube/icon.png",
              :text             => "YouTube",
              :selection_width  => 690,
              :selection_height => 530,
              :enabled          => true
            },
            :resource_selection => {
              :url              => "http://www.edu-apps.org/tool_redirect?id=youtube",
              :icon_url         => "http://www.edu-apps.org/tools/youtube/icon.png",
              :text             => "YouTube",
              :selection_width  => 690,
              :selection_height => 530,
              :enabled          => true
            },
            :icon_url=>"http://www.edu-apps.org/tools/youtube/icon.png"
          }
        }
        CC::Importer::BLTIConverter.any_instance.stubs(:retrieve_and_convert_blti_url).returns(mocked_bti_response)
        add_external_tool :url
      end

      it "should delete an external tool" do
        add_external_tool
        hover_and_click(".delete_tool_link:visible")
        fj('.ui-dialog button:contains(Delete):visible').click
        wait_for_ajax_requests
        tool = ContextExternalTool.last
        tool.workflow_state.should == "deleted"
        f("#external_tool#{tool.id} .name").should be_nil
      end

      it "should should edit an external tool" do
        add_external_tool
        new_description = "a different description"
        hover_and_click(".edit_tool_link:visible")
        replace_content(f("#external_tool_description"), new_description)
        fj('.ui-dialog button:contains(Submit):visible').click
        wait_for_ajax_requests
        tool = ContextExternalTool.last
        tool.description.should == new_description
      end
    end

    context "announcements tab" do
      it "should add an announcement" do
        notification = add_announcement
        notification.required_account_service.should be_nil
        notification.months_in_display_cycle.should be_nil
      end

      it "should delete an announcement" do
        add_announcement
        f(".delete_notification_link").click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        AccountNotification.count.should == 0
      end
    end
  end
end

describe 'shared settings specs' do
  describe "settings" do
    let(:account) { Account.default }
    let(:account_settings_url) { "/accounts/#{Account.default.id}/settings" }
    let(:admin_tab_url) { "/accounts/#{Account.default.id}/settings#tab-users" }
    include_examples "settings basic tests"
  end
end
