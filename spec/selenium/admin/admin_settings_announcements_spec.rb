require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/external_tools_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/basic/settings_specs')

describe "settings tabs" do
  def add_announcement
    f("#tab-announcements-link").click
    fj(".element_toggler:visible").click
    subject = "This is a date change"
    f("#account_notification_subject").send_keys(subject)
    f("#account_notification_icon .calendar").click

    ff("#add_notification_form .ui-datepicker-trigger")[0].click
    fln("1").click
    ff("#add_notification_form .ui-datepicker-trigger")[1].click
    fln("15").click

    type_in_tiny "textarea", "this is a message"
    yield if block_given?
    submit_form("#add_notification_form")
    wait_for_ajax_requests
    notification = AccountNotification.first
    expect(notification.message).to include_text("this is a message")
    expect(notification.subject).to include_text(subject)
    expect(notification.start_at.day).to eq 1
    expect(notification.end_at.day).to eq 15
    login_text = f("#header .user_name").text
    expect(f("#tab-announcements .announcement-details").text).to include_text(login_text)
    expect(f("#tab-announcements .notification_subject").text).to eq subject
    expect(f("#tab-announcements .notification_message").text).to eq "this is a message"
  end

  context "announcements tab" do
    include_examples "external tools tests"
    before(:each) do
      course_with_admin_logged_in
      get "/accounts/#{Account.default.id}/settings"
    end

    it "should add and delete an announcement" do
      add_announcement
      f(".delete_notification_link").click
      accept_alert
      wait_for_ajaximations
      expect(AccountNotification.count).to eq 0
    end
  end
end
