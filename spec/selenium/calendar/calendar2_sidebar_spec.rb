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
require_relative "../helpers/calendar2_common"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:once) do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
  end

  before do
    Account.default.tap do |a|
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    describe "sidebar" do
      describe "mini calendar" do
        it "adds the event class to days with events" do
          c = make_event
          get "/calendar2"

          events = ff("#minical .event")
          expect(events.size).to eq 1
          expect(Time.zone.parse(events.first["data-date"]).day).to eq(c.start_at.day)
        end

        it "changes the main calendars month on click", priority: "1" do
          title_selector = ".navigation_title"
          get "/calendar2"

          # turns out that sometimes you don't have any days from other months showing
          # whoda thunk that? (curse you february 2015!)
          while f("#minical .fc-other-month").nil?
            f("#minical .fc-button-prev").click
            wait_for_ajaximations
          end

          orig_titles = ff(title_selector).map(&:text)

          move_to_click("#minical td.fc-other-month.fc-day-number")

          expect(orig_titles).not_to eq ff(title_selector).map(&:text)
        end
      end

      it "shows the event in the mini calendar", priority: "1" do
        # lock to a particular day (the 13th because why not)
        # otherwise it turns out this spec will break on almost every 31st
        date = Date.new(Time.now.year, Time.now.month, 13) - 1.month
        assignment_model(course: @course,
                         title: "ricochet",
                         due_at: date.to_time)
        get "/calendar2"
        wait_for_ajax_requests

        # Because it is in a past month, it should not be on the mini calendar
        expect(f("#content")).not_to contain_css(".event")

        # Go back a month
        f(".fc-prev-button").click
        wait_for_ajaximations

        # look for the event on the mini calendar
        expect(f(".event")["data-date"]).to eq(date.strftime("%Y-%m-%d"))
      end

      describe "contexts list" do
        it "toggles event display when context is clicked" do
          make_event context: @course, start: Time.now
          get "/calendar2"

          f(".context_list_context .context-list-toggle-box").click
          context_course_item = fj(".context_list_context:nth-child(2)")
          expect(context_course_item).to have_class("checked")
          expect(f(".fc-event")).to be_displayed

          f(".context_list_context:nth-child(2) .context-list-toggle-box").click
          expect(context_course_item).to have_class("not-checked")
          expect(f("#content")).not_to contain_css(".fc_event")
        end

        it "constrains context selection to 10 by default" do
          create_courses 11, enroll_user: @user

          get "/calendar2"
          ff(".context_list_context").each(&:click)
          expect(ff(".context_list_context.checked").count).to eq 10
        end

        it "adjusts context selection limit based on account setting" do
          Account.default.tap do |a|
            a.settings[:calendar_contexts_limit] = 15
            a.save!
          end

          create_courses 17, enroll_user: @user

          get "/calendar2"
          ff(".context_list_context").each(&:click)
          expect(ff(".context_list_context.checked").count).to eq 15
        end

        it "validates calendar feed display" do
          get "/calendar2"

          f("#calendar-feed button").click
          expect(f("#calendar_feed_box")).to be_displayed
        end

        it "removes calendar item if calendar is unselected", priority: "1" do
          title = "blarg"
          make_event context: @course, start: Time.now, title: title
          load_month_view

          # expect event to be on the calendar
          expect(f(".fc-title").text).to include title

          # Click the toggle button. First button should be user, second should be course
          ff(".context-list-toggle-box")[1].click
          expect(f("#content")).not_to contain_css(".fc-title")

          # Turn back on the calendar and verify that your item appears
          ff(".context-list-toggle-box")[1].click
          expect(f(".fc-title").text).to include title
        end
      end

      describe "undated calendar items" do
        it "shows undated events after clicking link", priority: "1" do
          e = make_event start: nil, title: "pizza party"
          get "/calendar2"

          f("#undated-events-button").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          expect(undated_events.size).to eq 1
          expect(undated_events.first.text).to match(/#{e.title}/)
        end

        it "truncates very long undated event titles" do
          make_event start: nil, title: "asdfjkasldfjklasdjfklasdjfklasjfkljasdklfjasklfjkalsdjsadkfljasdfkljfsdalkjsfdlksadjklsadjsadklasdf"
          get "/calendar2"

          f("#undated-events-button").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          expect(undated_events.size).to eq 1
          expect(undated_events.first.text).to eq "asdfjkasldfjklasdjfklasdjfklasjf..."
        end
      end
    end
  end

  context "other calendars" do
    before :once do
      @root_account = Account.default
      @subaccount1 = @root_account.sub_accounts.create!(name: "SA-1", account_calendar_visible: true)
      @student = user_factory(active_all: true)
      Account.site_admin.enable_feature!(:account_calendar_events)
    end

    before do
      course_with_student_logged_in(user: @student, account: @subaccount1)
    end

    it "displays an empty state if there are no enabled accounts" do
      @student.set_preference(:enabled_account_calendars, nil)

      get "/calendar2"
      expect(f("#other-calendars-list-holder")).to be_displayed
      expect(f(".accounts-empty-state")).to be_displayed
    end

    it "displays accounts if the user has enabled them" do
      @student.set_preference(:enabled_account_calendars, @subaccount1.id)
      get "/calendar2"

      account_calendar = ff("#other-calendars-context-list > .context_list_context > label")
      expect(f("#other-calendars-list-holder")).to be_displayed
      expect(account_calendar.first.text).to eq @subaccount1.name
    end

    it "removes the account if the delete button is clicked" do
      @student.set_preference(:enabled_account_calendars, @subaccount1.id)
      get "/calendar2"

      account_calendar = ff("#other-calendars-context-list > .context_list_context > label")
      expect(account_calendar.first.text).to eq @subaccount1.name

      account_calendar_delete_btn = ff("#other-calendars-context-list > .context_list_context > .buttons-wrapper > .ContextList__DeleteBtn")
      hover(ff("#other-calendars-context-list > .context_list_context").first)
      account_calendar_delete_btn.first.click

      expect(f(".flashalert-message")).to be_displayed
      expect(f(".flashalert-message").text).to include "Calendar removed"
      expect(f(".accounts-empty-state")).to be_displayed
      driver.navigate.refresh
      expect(f(".accounts-empty-state")).to be_displayed
    end

    it "enables event creation for added account calendars" do
      account_admin_user(account: @subaccount1)
      user_session(@admin)
      get "/calendar2"
      event_title = "account event"
      f("button[data-testid='add-other-calendars-button']").click
      # because clicking the checkbox clicks on a sibling span
      driver.execute_script("$('input[data-testid=account-#{@subaccount1.id}-checkbox]').click()")
      f("button[data-testid='save-calendars-button']").click
      f(".flashalert-message button").click
      f("#create_new_event_link").click
      replace_content(edit_calendar_event_form_title, event_title)
      click_option(edit_calendar_event_form_context, @subaccount1.name)
      edit_calendar_event_form_submit_button.click
      wait_for_ajaximations
      assert_title(event_title, false)
    end

    it "does not show the account or its events if the account calendar is hidden" do
      event_title = "subaccount 1 event"
      @subaccount1.calendar_events.create!(title: event_title, start_at: 2.days.from_now)

      @student.set_preference(:enabled_account_calendars, [@subaccount1])
      user_session(@student)

      get "/calendar2"
      expect(f("#other-calendars-list-holder")).to contain_css("#other-calendars-context-list > li[data-context=account_#{@subaccount1.id}]")
      expect(f(".fc-body")).to contain_css(".fc-event")
      assert_title(event_title, false)

      @subaccount1.account_calendar_visible = false
      @subaccount1.save!

      driver.navigate.refresh
      expect(f("#other-calendars-list-holder")).not_to contain_css("#other-calendars-context-list > li[data-context=account_#{@subaccount1.id}]")
      expect(f(".fc-body")).not_to contain_css(".fc-event")
    end
  end
end
