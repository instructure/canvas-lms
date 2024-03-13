# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require_relative "../helpers/calendar2_common"
require_relative "pages/calendar_other_calendars_page"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include CalendarOtherCalendarsPage

  context "other calendars" do
    before :once do
      @root_account = Account.default
      @subaccount1 = @root_account.sub_accounts.create!(name: "SA-1", account_calendar_visible: true)
      @student = user_factory(active_all: true)
    end

    before do
      course_with_student_logged_in(user: @student, account: @subaccount1)
    end

    it "displays an empty state if there are no enabled accounts" do
      @student.set_preference(:enabled_account_calendars, nil)

      get "/calendar2"
      expect(other_calendars_container).to be_displayed
      expect(modal_empty_state).to be_displayed
    end

    it "displays accounts if the user has enabled them" do
      @student.set_preference(:enabled_account_calendars, @subaccount1.id)
      get "/calendar2"

      account_calendar = other_calendars_context_labels
      expect(other_calendars_container).to be_displayed
      expect(account_calendar.first.text).to eq @subaccount1.name
    end

    it "displays a NEW pill to indicate the feature is new" do
      @student.set_preference(:enabled_account_calendars, @subaccount1.id)
      get "/calendar2"

      expect(sidebar).to contain_css(".new-feature-pill")
      open_other_calendars_modal
      wait_for_ajax_requests
      modal_cancel_btn.click
      driver.navigate.refresh
      expect(sidebar).not_to contain_css(".new-feature-pill")
    end

    it "removes the account if the delete button is clicked" do
      @student.set_preference(:enabled_account_calendars, @subaccount1.id)
      get "/calendar2"

      account_calendar = other_calendars_context_labels
      expect(account_calendar.first.text).to eq @subaccount1.name

      hover(other_calendars_context.first)
      delete_calendar_btn.first.click

      expect(flash_alert).to be_displayed
      expect(flash_alert.text).to include "Calendar removed"
      expect(modal_empty_state).to be_displayed
      driver.navigate.refresh
      expect(modal_empty_state).to be_displayed
    end

    it "does not show the account or its events if the account calendar is hidden" do
      @subaccount2 = @root_account.sub_accounts.create!(name: "SA-2", account_calendar_visible: true)
      course_with_student_logged_in(user: @student, account: @subaccount2)
      event_title = "subaccount 1 event"
      Timecop.freeze(Time.zone.local(2022, 9, 5, 10, 5, 0)) do
        @subaccount1.calendar_events.create!(title: event_title, start_at: 0.days.from_now)

        @student.set_preference(:enabled_account_calendars, [@subaccount1.id, @subaccount2.id])
        user_session(@student)

        get "/calendar2#view_name=month&view_start=2022-09-05"
        expect(other_calendars_container).to contain_css(context_list_item_selector(@subaccount1.id))
        expect(calendar_body).to contain_css(calendar_event_selector)
        assert_title(event_title, false)

        @subaccount1.account_calendar_visible = false
        @subaccount1.save!

        driver.navigate.refresh
        expect(other_calendars_container).not_to contain_css(context_list_item_selector(@subaccount1.id))
        expect(calendar_body).not_to contain_css(calendar_event_selector)
      end
    end

    it "does not show the other calendars section if there are no account calendars available for the user" do
      @subaccount1.account_calendar_visible = false
      @subaccount1.save!
      user_session(@student)

      get "/calendar2"
      expect(sidebar).not_to contain_css(other_calendars_container_selector)
      expect(sidebar).not_to include_text("OTHER CALENDARS")
    end

    it "the NEW pill is shown only for unseen account calendars" do
      @student.set_preference(:viewed_auto_subscribed_account_calendars, [])
      @subaccount2 = @root_account.sub_accounts.create!(name: "SA-2", account_calendar_visible: true, account_calendar_subscription_type: "auto")
      course_with_student_logged_in(user: @student, account: @subaccount2)

      # for some reason, if I don't get some other page first, this spec will fetch /calendar2
      # twice at the top of this spec on subsequent runs when it's being run under the
      # flakey_spec_catcher. This is the only way I could find that resolved that.
      get "/"
      wait_for_dom_ready

      get "/calendar2"
      expect(sidebar).to contain_css(other_calendars_new_pill_selector)

      driver.navigate.refresh
      wait_for_dom_ready

      expect(sidebar).not_to contain_css(other_calendars_new_pill_selector)
    end

    context "Add other calendars modal" do
      it "adds an account calendar to the list of other calendars and shows its calendar events" do
        account_admin_user(account: @subaccount1)
        user_session(@admin)
        event_title = "event of #{@subaccount1.name}"
        Timecop.freeze(Time.zone.local(2022, 9, 1, 10, 5, 0)) do
          @subaccount1.calendar_events.create!(title: event_title, start_at: 0.days.from_now)
          get "/calendar2#view_name=month&view_start=2022-09-05"
          open_other_calendars_modal
          select_other_calendar(@subaccount1.id)
          click_modal_save_btn
          wait_for_ajaximations
          account_calendar = other_calendars_context_labels
          expect(other_calendars_container).to be_displayed
          expect(account_calendar.first.text).to eq @subaccount1.name
          assert_title(event_title, false)
        end
      end

      it "removes an account calendar from the list of other calendars and removes its calendar events" do
        @student.set_preference(:enabled_account_calendars, @subaccount1.id)
        user_session(@student)
        event_title = "event of #{@subaccount1.name}"
        Timecop.freeze(Time.zone.local(2022, 9, 1, 10, 5, 0)) do
          @subaccount1.calendar_events.create!(title: event_title, start_at: 0.days.from_now)
          get "/calendar2#view_name=month&view_start=2022-09-05"
          # Confirm the account calendar is active
          account_calendar = other_calendars_context_labels
          expect(account_calendar.first.text).to eq @subaccount1.name
          assert_title(event_title, false)
          # Removing the account calendar
          open_other_calendars_modal
          select_other_calendar(@subaccount1.id)
          click_modal_save_btn
          wait_for_ajaximations
          expect(other_calendars_container).not_to contain_css(context_list_item_selector(@subaccount1.id))
          expect(calendar_body).not_to contain_css(calendar_event_selector)
        end
      end

      it "keeps added account calendars as selected context after refreshing the page" do
        account_admin_user(account: @subaccount1)
        user_session(@admin)
        event_title = "event of #{@subaccount1.name}"
        Timecop.freeze(Time.zone.local(2022, 9, 1, 10, 5, 0)) do
          @subaccount1.calendar_events.create!(title: event_title, start_at: 0.days.from_now)
          get "/calendar2#view_name=month&view_start=2022-09-05"
          open_other_calendars_modal
          select_other_calendar(@subaccount1.id)
          click_modal_save_btn
          driver.navigate.refresh
          expect(other_calendars_container).to be_displayed
          expect(other_calendars_context_labels.first.text).to eq @subaccount1.name
          assert_title(event_title, false)
        end
      end

      it "adds multiple account calendars at once to the list of other calendars" do
        @subaccount2 = @root_account.sub_accounts.create!(name: "SA-2", account_calendar_visible: true)
        course_with_student_logged_in(user: @student, account: @subaccount2)
        user_session(@student)
        get "/calendar2"
        open_other_calendars_modal
        select_other_calendar(@subaccount1.id)
        select_other_calendar(@subaccount2.id)
        click_modal_save_btn
        expect(other_calendars_container).to be_displayed
        expect(other_calendars_context_labels.first.text).to eq @subaccount1.name
        expect(other_calendars_context_labels.second.text).to eq @subaccount2.name
      end

      it "cancels account calendars selection" do
        user_session(@student)
        get "/calendar2"
        open_other_calendars_modal
        select_other_calendar(@subaccount1.id)
        click_modal_cancel_btn
        expect(other_calendars_container).not_to contain_css(context_list_item_selector(@subaccount1.id))
      end

      it "enables event creation for added account calendars" do
        skip "FOO-3803 (9/7/2023)"
        account_admin_user(account: @subaccount1)
        user_session(@admin)
        get "/calendar2"
        event_title = "account event"
        open_other_calendars_modal
        select_other_calendar(@subaccount1.id)
        click_modal_save_btn
        close_flash_alert
        open_create_new_event_modal
        replace_content(edit_calendar_event_form_title, event_title)
        click_option(edit_calendar_event_form_context, @subaccount1.name)
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        assert_title(event_title, false)
      end

      context "search bar" do
        it "can search accounts with at least 2 characters" do
          saccount1 = @root_account.sub_accounts.create!(name: "Account-1", account_calendar_visible: true)
          saccount2 = @root_account.sub_accounts.create!(name: "Account-2", account_calendar_visible: true)
          course_with_student_logged_in(user: @student, account: saccount1)
          course_with_student_logged_in(user: @student, account: saccount2)

          user_session(@student)
          get "/calendar2"
          open_other_calendars_modal
          expect(account_calendars_list).to contain_css(account_calendar_checkbox_selector(@subaccount1.id))
          expect(account_calendar_list_items.count).to eq(3)

          search_account("Acc")
          expect(account_calendars_list).not_to contain_css(account_calendar_checkbox_selector(@subaccount1.id))
          expect(account_calendar_list_items.count).to eq(2)
        end

        it "displays an empty state if no matching accounts were found" do
          user_session(@student)
          get "/calendar2"
          open_other_calendars_modal
          expect(account_calendar_list_items.count).to eq(1)
          expect(account_calendars_list).not_to contain_css(modal_empty_state_selector)

          search_account("non")
          expect(modal_empty_state).to be_displayed
        end
      end
    end

    context "does not show links to unauthorized pages" do
      it "does not display the link to the event details page if the user is not authorized" do
        @student.set_preference(:enabled_account_calendars, @subaccount1.id)
        make_event(context: @subaccount1, start: 0.days.from_now, title: "account event")
        get "/calendar2"

        # event title is displayed but not as a link
        fj(calendar_event_selector).click
        expect(event_popover).to be_displayed
        expect(event_popover_title).to be_displayed
        expect(event_popover_title.text).to eq "account event"
        expect(event_popover_title).not_to contain_css(event_link_selector)
      end

      it "does not display the link to the calendar context if the user is not authorized" do
        @student.set_preference(:enabled_account_calendars, @subaccount1.id)
        make_event(context: @subaccount1, start: 0.days.from_now, title: "account event")
        get "/calendar2"

        # event context is displayed but not as a link
        fj(calendar_event_selector).click
        expect(event_popover).to be_displayed
        expect(event_popover_content).to be_displayed
        expect(event_popover_content).not_to contain_css("a")
      end
    end

    context "auto subscription for an account calendar" do
      before :once do
        @subaccount1.account_calendar_subscription_type = "auto"
        @subaccount1.save!
      end

      it "cannot uncheck auto-subscribed calendar on selection modal" do
        @student.set_preference(:enabled_account_calendars, @subaccount1.id)
        user_session(@student)
        get "/calendar2"

        open_other_calendars_modal
        expect(f(account_calendar_checkbox_selector(@subaccount1.id))).to be_disabled
      end

      it "can uncheck auto-subscribed calendar for viewing on calendar" do
        @student.set_preference(:enabled_account_calendars, @subaccount1.id)
        user_session(@student)
        get "/calendar2"

        account_calendar_available_list_item.click
        expect(account_calendar_available_list_item).not_to be_checked
      end
    end
  end
end
