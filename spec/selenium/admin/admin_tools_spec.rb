# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "admin_tools" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include CustomScreenActions

  def load_admin_tools_page
    get "/accounts/#{@account.id}/admin_tools"
    wait_for_ajaximations
  end

  def perform_user_search(form_sel, search_term, click_row = 0)
    set_value f("#{form_sel} input[name=search_term]"), search_term
    sleep 0.2 # 0.2 s delay before the search fires
    wait_for_ajaximations
    fj("#{form_sel} .roster tbody tr:nth(#{click_row}) td").click
  end

  def perform_autocomplete_search(field_sel, search_term, click_row = 0)
    set_value f(field_sel), search_term
    sleep 0.5
    wait_for_ajaximations
    autocomplete_value = fj(".ui-autocomplete.ui-menu > .ui-menu-item:nth(#{click_row}) > a")
    autocomplete_value.click
    autocomplete_value
  end

  def setup_users
    # Setup a student (@student)
    course_with_student(active_all: true, account: @account, user: user_with_pseudonym(name: "Student TestUser"))
    user_with_pseudonym(user: @student, account: @account)

    setup_account_admin
  end

  def setup_account_admin(permissions = { view_notifications: true })
    # Setup an account admin (@account_admin) and logged in.
    account_admin_user_with_role_changes(account: @account, role_changes: permissions)
    @account_admin = @admin
    user_with_pseudonym(user: @account_admin, account: @account)
    user_session(@account_admin)
  end

  def click_view_tab(tab_name)
    wait_for_ajaximations
    tab = fj("#adminToolsTabs .#{tab_name} > a")
    tab.click
    wait_for_ajaximations
  end

  def change_log_type(log_type)
    wait_for_ajaximations
    click_option("#loggingType", "#logging#{log_type}", :value)
    wait_for_ajaximations
  end

  def show_event_details(event_type, search_term = nil, event = nil)
    search_term ||= @course.name
    event ||= @event

    perform_autocomplete_search("#course_id-autocompleteField", search_term)
    f("#loggingCourse button[name=course_submit]").click
    wait_for_ajaximations

    cols = ffj("#courseLoggingSearchResults table tbody tr:last td")
    expect(cols[3].text).to eq event_type

    fj("#courseLoggingSearchResults table tbody tr:last td:last a").click
    expect(fj(".ui-dialog dl dd:first").text).to eq event.id
  end

  before do
    @account = Account.default
    setup_users
  end

  context "View Notifications" do
    before do
      @account.settings[:admins_can_view_notifications] = true
      @account.save!
    end

    def click_view_notifications_tab
      click_view_tab("notifications")
    end

    context "as SiteAdmin" do
      it "performs search without account setting or user permission" do
        @account.settings[:admins_can_view_notifications] = false
        @account.save!
        site_admin_user
        user_with_pseudonym(user: @admin, account: @account)
        user_session(@admin)
        message_model(user_id: @student.id, body: "this is my message", root_account_id: @account.id)

        load_admin_tools_page
        click_view_notifications_tab
        perform_user_search("#commMessagesSearchForm", @student.id)
        f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
        wait_for_ajaximations
        expect(f("#commMessagesSearchResults .message-body").text).to include("this is my message")
      end
    end

    context "as AccountAdmin" do
      context "with permissions" do
        it "performs search" do
          message_model(user_id: @student.id, body: "foo bar", root_account_id: @account.id)
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchResults .message-body").text).to include("foo bar")
        end

        it "displays nothing found" do
          message_model(user_id: @student.id, body: "foo bar", root_account_id: @account.id)
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          set_value f(".userDateRangeSearchModal .dateEndSearchField"), 2.months.ago
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchResults .alert").text).to include("No messages found")
          expect(f("#content")).not_to contain_css("#commMessagesSearchResults .message-body")
        end

        it "displays valid search params used" do
          message_model(user_id: @student.id, body: "foo bar", root_account_id: @account.id)
          load_admin_tools_page
          click_view_notifications_tab
          # Search with no dates
          perform_user_search("#commMessagesSearchForm", @student.id)
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchOverview").text).to include("Notifications sent to #{@student.name} from the beginning to now.")
          # Search with begin date and end date - should show time actually being used
          perform_user_search("#commMessagesSearchForm", @student.id)
          replace_and_proceed(f(".userDateRangeSearchModal .dateStartSearchField"), "Mar 3, 2001")
          replace_and_proceed(f(".userDateRangeSearchModal .dateEndSearchField"), "Mar 9, 2001")
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchOverview").text).to include("Notifications sent to #{@student.name} from Mar 3, 2001 at 12am to Mar 9, 2001 at 12am.")
          # Search with begin date/time and end date/time - should use and show given time
          perform_user_search("#commMessagesSearchForm", @student.id)
          replace_and_proceed(f(".userDateRangeSearchModal .dateStartSearchField"), "Mar 3, 2001 1:05p")
          replace_and_proceed(f(".userDateRangeSearchModal .dateEndSearchField"), "Mar 9, 2001 3p")
          f(".userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchOverview").text).to include("Notifications sent to #{@student.name} from Mar 3, 2001 at 1:05pm to Mar 9, 2001 at 3pm.")
        end

        it "filters with spanish" do
          # Setup with spanish locale
          skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
          @user.locale = "es-ES"
          @user.save!

          @account.default_locale = "es-ES"
          @account.save!

          Timecop.travel(Time.new(2010, 1, 3, 14, 35, 0)) do
            Messages::Partitioner.process
            message_model(user_id: @student.id, body: "foo bar", root_account_id: @account.id)
          end

          load_admin_tools_page
          click_view_notifications_tab

          # Search should find message, ene == Enero == January
          perform_user_search("#commMessagesSearchForm", @student.id)
          replace_and_proceed(f(".userDateRangeSearchModal .dateEndSearchField"), "4 ene 2010")
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchResults .message-body").text).to include("foo bar")

          # Search should not message
          perform_user_search("#commMessagesSearchForm", "")
          replace_and_proceed(f(".userDateRangeSearchModal .dateEndSearchField"), "2 ene 2010")
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          expect(f("#commMessagesSearchResults .alert").text).to include("No messages found")
        end

        it "displays an error when given invalid input data" do
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          # Search with invalid dates
          set_value f(".userDateRangeSearchModal .dateStartSearchField"), "couch"
          set_value f(".userDateRangeSearchModal .dateEndSearchField"), "pillow"
          f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
          wait_for_ajaximations
          assert_error_box("[name='messages_start_time']")
          assert_error_box("[name='messages_end_time']")
        end

        it "hides tab if account setting disabled" do
          @account.settings[:admins_can_view_notifications] = false
          @account.save!

          load_admin_tools_page
          wait_for_ajaximations
          expect(f("#adminToolsTabs")).not_to contain_css(".notifications")
        end
      end

      context "without permissions" do
        it "does not see tab" do
          setup_account_admin({ view_notifications: false })
          load_admin_tools_page
          wait_for_ajaximations
          expect(f("#adminToolsTabs")).not_to contain_css(".notifications")
        end
      end
    end
  end

  context "Logging" do
    it "changes log types with dropdown" do
      load_admin_tools_page
      click_view_tab "logging"

      select = fj("#loggingType")
      expect(select).not_to be_nil
      expect(select).to be_displayed

      change_log_type("Authentication")

      loggingTypeView = fj("#loggingAuthentication")
      expect(loggingTypeView).not_to be_nil
      expect(loggingTypeView).to be_displayed
    end

    context "permissions" do
      it "includes options activity with permissions" do
        setup_account_admin
        load_admin_tools_page
        wait_for_ajaximations

        tab = fj("#adminToolsTabs .logging > a")
        expect(tab).not_to be_nil
        expect(tab.text).to eq "Logging"

        click_view_tab "logging"

        select = fj("#loggingType")
        expect(select).not_to be_nil
        expect(select).to be_displayed

        options = ffj("#loggingType > option").map { |e| e.text.strip }
        expect(options).to include("Select a Log type")
        expect(options).to include("Login / Logout Activity")
        expect(options).to include("Grade Change Activity")
        expect(options).to include("Course Activity")
      end

      context "without permissions" do
        it "does not see tab" do
          setup_account_admin(
            view_statistics: false,
            manage_user_logins: false,
            view_grade_changes: false,
            view_course_changes: false
          )
          load_admin_tools_page
          wait_for_ajaximations
          expect(f("#adminToolsTabs")).not_to contain_css(".logging")
        end

        it "does not include login activity option for revoked permission" do
          setup_account_admin(view_statistics: false, manage_user_logins: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!(&:text)
          expect(options).not_to include("Login / Logout Activity")
        end

        it "does not include grade change activity option for revoked permission" do
          setup_account_admin(view_grade_changes: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!(&:text)
          expect(options).not_to include("Grade Change Activity")
        end

        it "does not include course change activity option for revoked permission" do
          setup_account_admin(view_course_changes: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!(&:text)
          expect(options).not_to include("Course Activity")
        end

        it "does not include course change activity option for sub-account admins" do
          sub_account = @account.sub_accounts.create!(name: "sub-account")
          sub_admin = account_admin_user(account: sub_account)
          user_with_pseudonym(user: sub_admin, account: sub_account)
          user_session(sub_admin)

          get "/accounts/#{sub_account.id}/admin_tools"
          wait_for_ajaximations

          click_view_tab "logging"

          options = ff("#loggingType > option")
          options.map!(&:text)
          expect(options).not_to include("Course Activity")
        end
      end
    end
  end

  context "Authentication Logging" do
    before do
      Timecop.freeze(8.seconds.ago) do
        Auditors::Authentication.record(@student.pseudonyms.first, "login")
      end
      Auditors::Authentication.record(@student.pseudonyms.first, "logout")
      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("Authentication")
    end

    it "shows log history" do
      perform_user_search("#authLoggingSearchForm", @student.id)
      f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
      wait_for_ajaximations
      expect(ff("#authLoggingSearchResults table tbody tr").length).to eq 2
      cols = ffj("#authLoggingSearchResults table tbody tr:first td")
      expect(cols.size).to eq 3
      expect(cols.last.text).to eq "LOGOUT"
    end

    it "searches by user name" do
      perform_user_search("#authLoggingSearchForm", "testuser")
      f(".userDateRangeSearchModal .userDateRangeSearchBtn").click
      wait_for_ajaximations
      expect(ff("#authLoggingSearchResults table tbody tr").length).to eq 2
    end
  end

  context "Grade Change Logging" do
    before do
      Timecop.freeze(8.seconds.ago) do
        course_with_teacher(course: @course, user: user_with_pseudonym(name: "Teacher TestUser"))
        @assignment = @course.assignments.create!(title: "Assignment", points_possible: 10)
      end

      Timecop.freeze(5.seconds.ago) do
        @submission = @assignment.grade_student(@student, grade: 7, grader: @teacher).first
      end

      Timecop.freeze(3.seconds.ago) do
        @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
      end

      @submission = @assignment.grade_student(@student, grade: 9, grader: @teacher, graded_anonymously: true).first

      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("GradeChange")
    end

    it "searches by grader name and show history" do
      perform_autocomplete_search("#grader_id-autocompleteField", @teacher.name)
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations
      expect(ff("#gradeChangeLoggingSearchResults table tbody tr").length).to eq 3

      cols = ffj("#gradeChangeLoggingSearchResults table tbody tr:last td")
      expect(cols.size).to eq 9

      expect(cols[2].text).to eq "-"
      expect(cols[3].text).to eq "7"
      expect(cols[4].text).to eq @teacher.name
      expect(cols[5].text).to eq @student.name
      expect(cols[6].text).to eq @course.name
      expect(cols[7].text).to eq @assignment.title
      expect(cols[8].text).to eq "n"
    end

    it "displays 'y' if graded anonymously" do
      perform_autocomplete_search("#grader_id-autocompleteField", @teacher.name)
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations

      cols = ffj("#gradeChangeLoggingSearchResults table tbody tr:first td")
      expect(cols[8].text).to eq "y"
    end

    it "searches by student name" do
      perform_autocomplete_search("#student_id-autocompleteField", @student.name)
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations
      expect(ff("#gradeChangeLoggingSearchResults table tbody tr").length).to eq 3
    end

    it "searches by course id" do
      set_value f("#gradeChangeCourseSearch"), @course.id
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations
      expect(ff("#gradeChangeLoggingSearchResults table tbody tr").length).to eq 3
    end

    it "searches by assignment id" do
      set_value f("#gradeChangeAssignmentSearch"), @assignment.id
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations
      scroll_page_to_bottom
      expect(ff("#gradeChangeLoggingSearchResults table tbody tr").length).to eq 3
    end

    it "fails gracefully with invalid ids" do
      set_value f("#gradeChangeAssignmentSearch"), "notarealid"
      f("#loggingGradeChange button[name=gradeChange_submit]").click
      wait_for_ajaximations
      expect(f("#gradeChangeLoggingSearchResults").text).to eq "No items found"
    end
  end

  context "Course Logging" do
    before do
      course_with_teacher(course: @course, user: user_with_pseudonym(name: "Teacher TestUser"))

      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("Course")
    end

    it "searches by course name and show history" do
      @events = []
      (1..5).each do |index|
        @course.name = "Course #{index}"
        @course.start_at = Date.today + index.days
        @course.conclude_at = @course.start_at + 7.days
        Timecop.freeze(index.seconds.from_now) do
          @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
        end
        @events << @event
      end
      @course.save

      perform_autocomplete_search("#course_id-autocompleteField", @course.name)
      f("#loggingCourse button[name=course_submit]").click
      wait_for_ajaximations

      expect(ff("#courseLoggingSearchResults table tbody tr").length).to eq @events.length
      cols = ffj("#courseLoggingSearchResults table tbody tr:last td")
      expect(cols.size).to eq 6

      expect(cols[2].text).to eq @teacher.name
      expect(cols[3].text).to eq "Updated"
      expect(cols[4].text).to eq "Manual"
      expect(cols[5].text).to eq "View Details"
    end

    it "searches by course id" do
      @course.name = "Course Updated"
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      set_value f("#course_id-autocompleteField"), @course.id
      f("#loggingCourse button[name=course_submit]").click
      wait_for_ajaximations
      cols = ffj("#courseLoggingSearchResults table tbody tr:last td")
      expect(cols.size).to eq 6
    end

    it "fails gracefully with invalid ids" do
      set_value f("#course_id-autocompleteField"), "notarealid"
      f("#loggingCourse button[name=course_submit]").click
      wait_for_ajaximations
      expect(f("#courseLoggingSearchResults ").text).to eq "No items found"
    end

    it "finds courses in any workflow state" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      @course.destroy

      autocomplete_value = perform_autocomplete_search("#course_id-autocompleteField", @course.name)
      expect(autocomplete_value).not_to be_nil

      f("#loggingCourse button[name=course_submit]").click
      wait_for_ajaximations

      cols = ffj("#courseLoggingSearchResults table tbody tr:last td")
      expect(cols.size).to eq 6
    end

    it "shows created event details" do
      # Simulate a new course
      course = Course.new
      course.name = @course.name
      @event = Auditors::Course.record_created(@course, @teacher, course.changes)

      show_event_details("Created")
      cols = ffj(".ui-dialog table:first tbody tr:first td")
      expect(cols.size).to eq 2
      expect(cols[0].text).to eq "Name"
      expect(cols[1].text).to eq @course.name
    end

    it "shows updated event details" do
      old_name = @course.name
      @course.name = "Course Updated"
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      show_event_details("Updated", old_name)
      items = ffj(".ui-dialog dl > dd")
      expect(items[4].text).to eq "Manual"
      expect(items[5].text).to eq "Updated"

      cols = ffj(".ui-dialog table:first tbody tr:first td")
      expect(cols.size).to eq 3
      expect(cols[0].text).to eq "Name"
      expect(cols[1].text).to eq old_name
      expect(cols[2].text).to eq @course.name
    end

    it "shows sis batch id if source is sis" do
      old_name = @course.name
      @course.name = "Course Updated"

      sis_batch = @account.root_account.sis_batches.create
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes, source: :sis, sis_batch:)

      show_event_details("Updated", old_name)
      items = ffj(".ui-dialog dl > dd")
      expect(items[4].text).to eq "SIS"
      expect(items[5].text).to eq sis_batch.id.to_s
    end

    it "shows concluded event details" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      show_event_details("Concluded")
    end

    it "shows unconcluded event details" do
      @event = Auditors::Course.record_unconcluded(@course, @teacher)
      show_event_details("Unconcluded")
    end

    it "shows deleted event details" do
      @event = Auditors::Course.record_deleted(@course, @teacher)
      show_event_details("Deleted")
    end

    it "shows restored event details" do
      @event = Auditors::Course.record_restored(@course, @teacher)
      show_event_details("Restored")
    end

    it "shows published event details" do
      @event = Auditors::Course.record_published(@course, @teacher)
      show_event_details("Published")
    end

    it "shows copied_to event details" do
      @course, @copied_course = @course, course_factory(active_course: true, course_name: "Copied Course")
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copied_course, @teacher)

      show_event_details("Copied To", @course.name, @to_event)
      expect(fj(".ui-dialog dl dd:last").text).to eq @copied_course.name
    end

    it "shows copied_from event details" do
      @course, @copied_course = @course, course_factory(active_course: true, course_name: "Copied Course")
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copied_course, @teacher)

      show_event_details("Copied From", @copied_course.name, @from_event)
      expect(fj(".ui-dialog dl dd:last").text).to eq @course.name
    end

    it "shows reset_to event details" do
      @course, @reset_course = @course, course_factory(active_course: true, course_name: "Reset Course")
      @from_event, @to_event = Auditors::Course.record_reset(@course, @reset_course, @teacher)

      show_event_details("Reset To", @course.name, @to_event)
      expect(fj(".ui-dialog dl dd:last").text).to eq @reset_course.name
    end

    it "shows reset_from event details" do
      @course, @reset_course = @course, course_factory(active_course: true, course_name: "Reset Course")
      @from_event, @to_event = Auditors::Course.record_reset(@course, @reset_course, @teacher)

      show_event_details("Reset From", @reset_course.name, @from_event)
      expect(fj(".ui-dialog dl dd:last").text).to eq @course.name
    end
  end

  context "bounced emails search" do
    before do
      u1 = user_with_pseudonym
      u2 = user_with_pseudonym
      u1.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
        cc.workflow_state = "active"
        cc.bounce_count = 1
        cc.last_bounce_at = 2.days.ago
      end
      u1.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
        cc.workflow_state = "active"
        cc.bounce_count = 2
        cc.last_bounce_at = 4.days.ago
      end
      u2.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
        cc.workflow_state = "active"
        cc.bounce_count = 3
        cc.last_bounce_at = 6.days.ago
        cc.last_bounce_details = { "bouncedRecipients" => [{ "diagnosticCode" => "550 what a luser" }] }
      end
      @user = @account_admin
    end

    it "does not appear if the user lacks permission" do
      load_admin_tools_page
      expect(f("#adminToolsTabNav")).not_to contain_css('a[href="#bouncedEmailsPane"]')
    end

    it "performs searches" do
      skip "FOO-4092"
      @account.settings[:admins_can_view_notifications] = true
      @account.save!
      load_admin_tools_page
      f('a[href="#bouncedEmailsPane"]').click
      replace_content fj('label:contains("Address") input'), "*@example.com"
      replace_content fj('label:contains("Last bounced after") input'), 5.days.ago.iso8601
      replace_content fj('label:contains("Last bounced before") input'), 3.days.ago.iso8601
      fj('button:contains("Search")').click
      wait_for_ajaximations
      data = f("#bouncedEmailsPane").text
      expect(data).not_to include "one@example.com"
      expect(data).to include "two@example.com"
      expect(data).not_to include "three@example.com"
      csvLink = fj("#bouncedEmailsPane a:contains('Download these results as CSV')")["href"]
      expect(csvLink).to include "/api/v1/accounts/#{@account.id}/bounced_communication_channels.csv?order=desc&pattern=*%40example.com"
    end
  end
end
