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
    f(".ui-datepicker-next").click
    fln("1").click
    ff("#add_notification_form .ui-datepicker-trigger")[1].click
    f(".ui-datepicker-next").click
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

  def edit_announcement
    notification = AccountNotification.first
    f("#notification_edit_#{notification.id}").click
    new_text = "...edited"
    f("#account_notification_subject_#{notification.id}").send_keys(new_text)
    f("#account_notification_icon .warning").click
    type_in_tiny("textarea", new_text)
    f(".account_notification_role_cbx").click
    ff(".edit_notification_form .ui-datepicker-trigger")[0].click
    fln("2").click
    ff(".edit_notification_form .ui-datepicker-trigger")[1].click
    fln("16").click
    f("#edit_notification_form_#{notification.id}").submit
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

    it "should edit an announcement" do
      add_announcement
      edit_announcement
      notification = AccountNotification.first
      expect(notification.subject).to eq "This is a date change...edited"
      expect(notification.message).to eq "<p>this is a message...edited</p>"
      expect(notification.icon).to eq "warning"
      expect(notification.account_notification_roles.count).to eq 1
      expect(notification.start_at.day).to eq 2
      expect(notification.end_at.day).to eq 16
    end
  end
end
