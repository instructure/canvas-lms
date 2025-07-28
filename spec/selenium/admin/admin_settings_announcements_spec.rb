# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../common"

describe "settings tabs" do
  context "announcements tab" do
    include_context "in-process server selenium tests"

    def add_announcement
      wait_for_ajaximations
      f("#tab-announcements").click
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
      expect(f("#tab-announcements-mount .announcement-details")).to include_text(displayed_username)
      dismiss_flash_messages

      # close the "user account" Tray that opened so we could read the displayed username
      f("body").click
      expect(f("body")).not_to contain_css('[aria-label="Profile tray"]')

      expect(f("#tab-announcements-mount .notification_subject").text).to eq subject
      expect(f("#tab-announcements-mount .notification_message").text).to eq "this is a message"
    end

    def edit_announcement(notification)
      f("#notification_edit_#{notification.id}").click
      replace_content f("#account_notification_subject_#{notification.id}"), "edited subject"
      f("#account_notification_icon_#{notification.id} .warning").click
      textarea_selector = "textarea#account_notification_message_#{notification.id}"
      type_in_tiny(textarea_selector, "edited message", clear: true)
      force_click("label:contains('Student')")
      ff(".edit_notification_form .ui-datepicker-trigger")[0].click
      fln("2").click
      ff(".edit_notification_form .ui-datepicker-trigger")[1].click
      fln("16").click
      f("#edit_notification_form_#{notification.id}").submit
    end

    before do
      course_with_admin_logged_in
    end

    it "adds and deletes an announcement" do
      get "/accounts/#{Account.default.id}/settings"
      add_announcement
      f(".delete_notification_link").click
      accept_alert
      wait_for_ajaximations
      expect(AccountNotification.active.count).to eq 0
    end

    it "checks title length" do
      get "/accounts/#{Account.default.id}/settings"
      wait_for_ajaximations
      f("#tab-announcements").click
      wait_for_ajaximations
      fj(".element_toggler:visible").click
      long_subject = "yikers " * 42
      f("#account_notification_subject").send_keys(long_subject)
      submit_form("#add_notification_form")
      wait_for_ajaximations
      assert_error_box("#account_notification_subject")
    end

    it "edits an announcement" do
      notification = account_notification(user: @user)
      initial_notification_start = notification.start_at
      initial_notification_end = notification.end_at
      get "/accounts/#{Account.default.id}/settings"
      f("#tab-announcements").click
      edit_announcement(notification)
      notification.reload
      expect(notification.subject).to eq "edited subject"
      expect(notification.message).to eq "<p>edited message</p>"
      expect(notification.icon).to eq "warning"
      expect(notification.account_notification_roles.count).to eq 1
      expect(notification.start_at).not_to eq initial_notification_start
      expect(notification.end_at).not_to eq initial_notification_end
    end

    it "copies and saves an announcement" do
      notification = account_notification(user: @user)
      get "/accounts/#{Account.default.id}/settings"
      wait_for_new_page_load
      f("#tab-announcements").click
      wait_for_ajax_requests
      # Setting up the content for copy
      f(".ic-notification__admin-actions button:nth-of-type(2)").click

      force_click("label:contains('Student')")
      force_click("label:contains('Teacher')")
      ff(".edit_notification_form .ui-datepicker-trigger")[0].click
      fln("5").click
      ff(".edit_notification_form .ui-datepicker-trigger")[1].click
      fln("15").click
      f("form button.btn.btn-primary").click

      notification.reload

      # Checking if content saved properly
      expect(notification.subject).to eq "this is a subject"
      expect(notification.message).to eq "<p>hi there</p>"
      expect(notification.icon).to eq "warning"
      expect(notification.account_notification_roles.count).to eq 2
      expect(notification.start_at.day).to eq 5
      expect(notification.end_at.day).to eq 15

      # Copy content
      f(".ic-notification__admin-actions button:nth-of-type(1)").click

      # Checking if content copied properly
      expect(element_value_for_attr(f("#account_notification_subject"), "value")).to eq "this is a subject"
      expect(element_value_for_attr(f("#account_notification_message"), "value")).to eq "<p>hi there</p>"
      expect(element_value_for_attr(f("#account_notification_icon"), "value")).to eq "warning"
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[0], "checked")).to eq "true"
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[1], "checked")).to eq "true"
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[2], "checked")).to be_nil
      expect(element_value_for_attr(f("#account_notification_start_at"), "value")).to include "5 at"
      expect(element_value_for_attr(f("#account_notification_end_at"), "value")).to include "15 at"

      # Saving copied content
      submit_form("#add_notification_form")
      wait_for_ajax_requests

      # Checking if copied content has been saved as new item
      expect(AccountNotification.active.count).to eq 2
    end

    it "resets form properly on new announcement" do
      notification = account_notification(user: @user)
      get "/accounts/#{Account.default.id}/settings"
      wait_for_new_page_load
      f("#tab-announcements").click
      wait_for_ajax_requests
      # Setting up the content for copy
      f(".ic-notification__admin-actions button:nth-of-type(2)").click
      force_click("label:contains('Student')")
      force_click("label:contains('Teacher')")
      ff(".edit_notification_form .ui-datepicker-trigger")[0].click
      fln("5").click
      ff(".edit_notification_form .ui-datepicker-trigger")[1].click
      fln("15").click
      f("form button.btn.btn-primary").click
      notification.reload

      # Copy content
      f(".ic-notification__admin-actions button:nth-of-type(1)").click

      # Close and reopen form
      fj(".element_toggler:visible").click
      fj(".element_toggler:visible").click

      # Checking if form got reset
      expect(element_value_for_attr(f("#account_notification_subject"), "value")).to eq ""
      expect(element_value_for_attr(f("#account_notification_message"), "value")).to eq ""
      expect(element_value_for_attr(f("#account_notification_icon"), "value")).to eq "information"
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[0], "checked")).to be_nil
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[1], "checked")).to be_nil
      expect(element_value_for_attr(ff("[id^=account_notification_role_]")[2], "checked")).to be_nil
      expect(element_value_for_attr(f("#account_notification_start_at"), "value")).to eq ""
      expect(element_value_for_attr(f("#account_notification_end_at"), "value")).to eq ""
    end

    context "messages" do
      it "lets you mark the checkbox to send messages for a new announcement" do
        get "/accounts/#{Account.default.id}/settings"
        wait_for_ajaximations
        f("#tab-announcements").click
        fj(".element_toggler:visible").click

        f("#account_notification_subject").send_keys("some name")
        type_in_tiny "textarea", "this is a message"
        replace_and_proceed(f("#account_notification_start_at"), 2.days.from_now.to_date.to_s)
        replace_and_proceed(f("#account_notification_end_at"), 3.days.from_now.to_date.to_s)

        f("label[for=account_notification_send_message]").click
        submit_form("#add_notification_form")
        wait_for_ajax_requests
        notification = AccountNotification.last
        expect(notification.send_message).to be true
        job = Delayed::Job.where(tag: "AccountNotification#broadcast_messages").last
        expect(job.run_at.to_i).to eq notification.start_at.to_i
      end

      it "does not show option for site admins" do
        skip("VICE-5335")
        user_session(site_admin_user)
        get "/accounts/#{Account.site_admin.id}/settings"
        wait_for_ajaximations
        f("#tab-announcements").click
        wait_for_ajaximations
        fj(".element_toggler:visible").click
        wait_for_ajaximations
        notification_form = f("#add_notification_form")
        expect(notification_form).to_not contain_css("label[for=account_notification_send_message]")
      end

      it "is able to send messages for an existing announcement" do
        notification = account_notification(start_at: 2.days.from_now, end_at: 4.days.from_now)
        get "/accounts/#{Account.default.id}/settings"
        wait_for_ajaximations
        f("#tab-announcements").click
        wait_for_ajaximations
        f("#notification_edit_#{notification.id}").click
        replace_content f("#account_notification_subject_#{notification.id}"), "edited subject"
        f("label[for=account_notification_send_message_#{notification.id}]").click
        f("form button.btn.btn-primary").click
        wait_for_ajax_requests
        notification.reload
        expect(notification.send_message).to be true
        job = Delayed::Job.where(tag: "AccountNotification#broadcast_messages").last
        expect(job.run_at.to_i).to eq notification.start_at.to_i
      end

      it "marks the checkbox already for a pending announcement already slated to send messages" do
        old_start_at = 1.day.from_now
        notification = account_notification(start_at: old_start_at, end_at: 5.days.from_now, send_message: true)
        job = Delayed::Job.where(tag: "AccountNotification#broadcast_messages").last
        expect(job.run_at.to_i).to eq old_start_at.to_i

        get "/accounts/#{Account.default.id}/settings"
        wait_for_ajaximations
        f("#tab-announcements").click
        wait_for_ajaximations
        f(".ic-notification__admin-actions button:nth-of-type(1)").click
        wait_for_ajaximations
        expect(is_checked("#account_notification_send_message_#{notification.id}")).to be_truthy # checked still
      end

      it "is able to re-send messages for an announcement" do
        notification = account_notification(start_at: 1.day.from_now, end_at: 5.days.from_now)
        wait_for_ajaximations
        AccountNotification.where(id: notification).update_all(send_message: true, messages_sent_at: 1.day.ago)
        get "/accounts/#{Account.default.id}/settings"
        wait_for_ajaximations
        f("#tab-announcements").click
        wait_for_ajaximations
        expect(f("#account_notification_subject")).to be_present
        f("button.edit_notification_toggle_focus").click
        wait_for_ajaximations
        expect(is_checked("#account_notification_send_message_#{notification.id}")).to be_falsey
        label = f("label[for=account_notification_send_message_#{notification.id}]")
        expect(label).to include_text("Re-send notification")
        label.click
        wait_for_ajaximations
        f("form button.btn.btn-primary").click
        wait_for_ajax_requests
        expect(AccountNotification.where(id: notification).last.updated_at).to be > notification.updated_at
      end
    end
  end
end
