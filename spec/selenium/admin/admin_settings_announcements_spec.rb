require_relative '../common'

describe "settings tabs" do
  context "announcements tab" do
    include_context "in-process server selenium tests"

    def add_announcement
      wait_for_ajaximations
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
      expect(notification.message).to include("this is a message")
      expect(notification.subject).to include(subject)
      expect(notification.start_at.day).to eq 1
      expect(notification.end_at.day).to eq 15
      expect(f("#tab-announcements .announcement-details")).to include_text(displayed_username)
      dismiss_flash_messages

      if ENV['CANVAS_FORCE_USE_NEW_STYLES']
        # close the "user account" reactTray that opened so we could read the displayed username
        if tray_close = f('.ReactTray__closeBtn')
         tray_close.click
        end
        expect(f('body')).not_to contain_css('.ReactTray__Overlay')
      end

      expect(f("#tab-announcements .notification_subject").text).to eq subject
      expect(f("#tab-announcements .notification_message").text).to eq "this is a message"
    end

    def edit_announcement(notification)
      f("#notification_edit_#{notification.id}").click
      replace_content f("#account_notification_subject_#{notification.id}"), "edited subject"
      f("#account_notification_icon .warning").click
      textarea_selector = "textarea#account_notification_message_#{notification.id}"
      type_in_tiny(textarea_selector, "edited message", clear: true)

      cb = f(".account_notification_role_cbx")
      f("label[for=#{cb['id']}]").click

      ff(".edit_notification_form .ui-datepicker-trigger")[0].click
      fln("2").click
      ff(".edit_notification_form .ui-datepicker-trigger")[1].click
      fln("16").click
      f("#edit_notification_form_#{notification.id}").submit
    end

    before do
      course_with_admin_logged_in
      driver.manage.window.maximize
    end

    it "should add and delete an announcement" do
      get "/accounts/#{Account.default.id}/settings"
      add_announcement
      f(".delete_notification_link").click
      accept_alert
      wait_for_ajaximations
      expect(AccountNotification.count).to eq 0
    end

    it "should edit an announcement" do
      skip_if_chrome('issue with edit_announcement method')
      notification = account_notification(user: @user)
      get "/accounts/#{Account.default.id}/settings"
      f("#tab-announcements-link").click
      edit_announcement(notification)
      notification.reload
      expect(notification.subject).to eq "edited subject"
      expect(notification.message).to eq "<p>edited message</p>"
      expect(notification.icon).to eq "warning"
      expect(notification.account_notification_roles.count).to eq 1
      expect(notification.start_at.day).to eq 2
      expect(notification.end_at.day).to eq 16
    end
  end
end
