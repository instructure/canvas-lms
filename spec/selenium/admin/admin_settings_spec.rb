require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/external_tools_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "admin settings tabs" do
  it_should_behave_like "external tools tests"
  before (:each) do
    course_with_admin_logged_in
    get "/accounts/#{Account.default.id}/settings"
  end

  context "external tools tab" do
    before (:each) do
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
      add_external_tool :url
    end

    it "should delete an external tool" do
      add_external_tool
      hover_and_click(".delete_tool_link:visible")
      driver.switch_to.alert.accept
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
      f(".save_button").click
      wait_for_ajax_requests
      tool = ContextExternalTool.last
      tool.description.should == new_description
      f("#external_tool_#{tool.id} .description").text.should == new_description
    end
  end

  context "announcements tab" do
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
      fj(".element_toggler:visible").click
      subject = "This is a file"
      f("#account_notification_subject").send_keys(subject)
      f("#account_notification_icon .file").click
      ff("#add_notification_form .ui-datepicker-trigger")[0].click
      today = date_chooser
      ff("#add_notification_form .ui-datepicker-trigger")[1].click
      tomorrow = date_chooser("t")
      type_in_tiny "textarea", "this is a message"
      submit_form("#add_notification_form")
      wait_for_ajax_requests
      notification = AccountNotification.first
      notification.message.should include_text("this is a message")
      notification.subject.should include_text(subject)
      notification.start_at.to_s.should include_text today
      notification.end_at.to_s.should include_text tomorrow
      f("#tab-announcements .user_content").text.should == "this is a message"
    end

    before (:each) do
      f("#tab-announcements-link").click
    end

    it "should add an announcement" do
      add_announcement
    end

    it "should delete an announcement" do
      add_announcement
      f(".delete_notification_link").click
      driver.switch_to.alert.accept
      wait_for_animations
      AccountNotification.count.should == 0
    end
  end
end

describe 'shared settings specs' do
  describe "settings" do
    let(:account) { Account.default }
    let(:account_settings_url) { "/accounts/#{Account.default.id}/settings" }
    let(:admin_tab_url) { "/accounts/#{Account.default.id}/settings#tab-users" }
    it_should_behave_like "settings basic tests"
  end
end
