require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/../cassandra_spec_helper')

describe "admin_tools" do
  include_examples "in-process server selenium tests"

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
    course_with_student(:active_all => true, :account => @account, :user => user_with_pseudonym(:name => 'Student TestUser'))
    user_with_pseudonym(:user => @student, :account => @account)

    setup_account_admin
  end

  def setup_account_admin(permissions = {:view_notifications => true})
    # Setup an account admin (@account_admin) and logged in.
    account_admin_user_with_role_changes(:account => @account, :role_changes => permissions)
    @account_admin = @admin
    user_with_pseudonym(:user => @account_admin, :account => @account)
    user_session(@account_admin)
  end

  def click_view_tab(tab_name)
    wait_for_ajaximations
    tab = fj("#adminToolsTabs .#{tab_name} > a")
    expect(tab).not_to be_nil
    expect(tab).to be_displayed
    tab.click
    wait_for_ajaximations
  end

  def change_log_type(log_type)
    wait_for_ajaximations
    click_option("#loggingType", "\#logging#{log_type}", :value)
    wait_for_ajaximations
  end

  def show_event_details(event_type, search_term = nil, event = nil)
    search_term ||= @course.name
    event ||= @event

    perform_autocomplete_search("#course_id-autocompleteField", search_term)
    f('#loggingCourse button[name=course_submit]').click
    wait_for_ajaximations

    cols = ffj('#courseLoggingSearchResults table tbody tr:last td')
    expect(cols[3].text).to eq event_type

    fj('#courseLoggingSearchResults table tbody tr:last td:last a').click
    expect(fj('.ui-dialog dl dd:first').text).to eq event.id
  end

  before do
    @account = Account.default
    setup_users
  end

  context "View Notifications" do
    before :each do
      @account.settings[:admins_can_view_notifications] = true
      @account.save!
    end

    def click_view_notifications_tab
      click_view_tab("notifications")
    end

    context "as SiteAdmin" do
      it "should perform search without account setting or user permission" do
        @account.settings[:admins_can_view_notifications] = false
        @account.save!
        site_admin_user
        user_with_pseudonym(:user => @admin, :account => @account)
        user_session(@admin)
        message(:user_id => @student.id, :body => 'this is my message', :account_id => @account.id)

        load_admin_tools_page
        click_view_notifications_tab
        perform_user_search("#commMessagesSearchForm", @student.id)
        f('#commMessagesSearchForm .userDateRangeSearchBtn').click
        wait_for_ajaximations
        expect(f('#commMessagesSearchResults .message-body').text).to include('this is my message')
      end
    end

    context "as AccountAdmin" do
      context "with permissions" do
        it "should perform search" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchResults .message-body').text).to include('nice body')
        end

        it "should display nothing found" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          set_value f('#commMessagesSearchForm .dateEndSearchField'), 2.months.ago
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchResults .alert').text).to include('No messages found')
          expect(f('#commMessagesSearchResults .message-body')).to be_nil
        end

        it "should display valid search params used" do
          message(:user_id => @student.id)
          load_admin_tools_page
          click_view_notifications_tab
          # Search with no dates
          perform_user_search("#commMessagesSearchForm", @student.id)
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchOverview').text).to include("Notifications sent to #{@student.name} from the beginning to now.")
          # Search with begin date and end date - should show time actually being used
          perform_user_search("#commMessagesSearchForm", @student.id)
          set_value f('#commMessagesSearchForm .dateStartSearchField'), 'Mar 3, 2001'
          set_value f('#commMessagesSearchForm .dateEndSearchField'), 'Mar 9, 2001'
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchOverview').text).to include("Notifications sent to #{@student.name} from Mar 3, 2001 at 12:00am to Mar 9, 2001 at 12:00am.")
          # Search with begin date/time and end date/time - should use and show given time
          perform_user_search("#commMessagesSearchForm", @student.id)
          set_value f('#commMessagesSearchForm .dateStartSearchField'), 'Mar 3, 2001 1:05p'
          set_value f('#commMessagesSearchForm .dateEndSearchField'), 'Mar 9, 2001 3p'
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchOverview').text).to include("Notifications sent to #{@student.name} from Mar 3, 2001 at 1:05pm to Mar 9, 2001 at 3:00pm.")
        end

        it "should display search params used when given invalid input data" do
          load_admin_tools_page
          click_view_notifications_tab
          perform_user_search("#commMessagesSearchForm", @student.id)
          # Search with invalid dates
          set_value f('#commMessagesSearchForm .dateStartSearchField'), 'couch'
          set_value f('#commMessagesSearchForm .dateEndSearchField'), 'pillow'
          f('#commMessagesSearchForm .userDateRangeSearchBtn').click
          wait_for_ajaximations
          expect(f('#commMessagesSearchOverview').text).to include("Notifications sent to #{@student.name} from the beginning to now.")
        end

        it "should hide tab if account setting disabled" do
          @account.settings[:admins_can_view_notifications] = false
          @account.save!

          load_admin_tools_page
          wait_for_ajaximations
          tab = fj('#adminToolsTabs .notifications > a')
          expect(tab).to be_nil
        end
      end

      context "without permissions" do
        it "should not see tab" do
          setup_account_admin({:view_notifications => false})
          load_admin_tools_page
          wait_for_ajaximations
          tab = fj('#adminToolsTabs .notifications > a')
          expect(tab).to be_nil
        end
      end
    end
  end

  context "Logging" do
    include_examples "cassandra audit logs"

    it "should change log types with dropdown" do
      load_admin_tools_page
      click_view_tab "logging"

      select = fj('#loggingType')
      expect(select).not_to be_nil
      expect(select).to be_displayed

      change_log_type("Authentication")

      loggingTypeView = fj('#loggingAuthentication')
      expect(loggingTypeView).not_to be_nil
      expect(loggingTypeView).to be_displayed
    end

    context "permissions" do
      it "should includ options activity with permissions" do
        setup_account_admin
        load_admin_tools_page
        wait_for_ajaximations

        tab = fj('#adminToolsTabs .logging > a')
        expect(tab).not_to be_nil
        expect(tab.text).to eq "Logging"

        click_view_tab "logging"

        select = fj('#loggingType')
        expect(select).not_to be_nil
        expect(select).to be_displayed

        options = ffj("#loggingType > option")
        options.map!{ |o| o.text }
        expect(options).to include("Select a Log type")
        expect(options).to include("Login / Logout Activity")
        expect(options).to include("Grade Change Activity")
        expect(options).to include("Course Activity")
      end

      context "without permissions" do
        it "should not see tab" do
          setup_account_admin(
            view_statistics: false,
            manage_user_logins: false,
            view_grade_changes: false,
            view_course_changes: false
          )
          load_admin_tools_page
          wait_for_ajaximations
          tab = fj('#adminToolsTabs .logging > a')
          expect(tab).to be_nil
        end

        it "should not include login activity option for revoked permission" do
          setup_account_admin(view_statistics: false, manage_user_logins: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!{ |o| o.text }
          expect(options).not_to include("Login / Logout Activity")
        end

        it "should not include grade change activity option for revoked permission" do
          setup_account_admin(view_grade_changes: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!{ |o| o.text }
          expect(options).not_to include("Grade Change Activity")
        end

        it "should not include course change activity option for revoked permission" do
          setup_account_admin(view_course_changes: false)
          load_admin_tools_page
          wait_for_ajaximations

          click_view_tab "logging"

          options = ffj("#loggingType > option")
          options.map!{ |o| o.text }
          expect(options).not_to include("Course Activity")
        end
      end
    end
  end

  context "Authentication Logging" do
    include_examples "cassandra audit logs"

    before do
      Timecop.freeze(8.seconds.ago) do
        Auditors::Authentication.record(@student.pseudonyms.first, 'login')
      end
      Auditors::Authentication.record(@student.pseudonyms.first, 'logout')
      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("Authentication")
    end

    it "should show log history" do
      perform_user_search("#authLoggingSearchForm", @student.id)
      f('#authLoggingSearchForm .userDateRangeSearchBtn').click
      wait_for_ajaximations
      expect(ff('#authLoggingSearchResults table tbody tr').length).to eq 2
      cols = ffj('#authLoggingSearchResults table tbody tr:first td')
      expect(cols.size).to eq 3
      expect(cols.last.text).to eq "LOGOUT"
    end

    it "should search by user name" do
      perform_user_search("#authLoggingSearchForm", 'testuser')
      f('#authLoggingSearchForm .userDateRangeSearchBtn').click
      wait_for_ajaximations
      expect(ff('#authLoggingSearchResults table tbody tr').length).to eq 2
    end
  end

  context "Grade Change Logging" do
    include_examples "cassandra audit logs"

    before do
      Timecop.freeze(8.seconds.ago) do
        course_with_teacher(course: @course, :user => user_with_pseudonym(:name => 'Teacher TestUser'))
        @assignment = @course.assignments.create!(:title => 'Assignment', :points_possible => 10)
      end

      Timecop.freeze(5.seconds.ago) do
        @submission = @assignment.grade_student(@student, grade: 7, grader: @teacher).first
      end

      Timecop.freeze(3.seconds.ago) do
        @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
      end

      @submission = @assignment.grade_student(@student, grade: 9, grader: @teacher).first

      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("GradeChange")
    end

    it "should search by grader name and show history" do
      perform_autocomplete_search("#grader_id-autocompleteField", @teacher.name)
      f('#loggingGradeChange button[name=gradeChange_submit]').click
      wait_for_ajaximations
      expect(ff('#gradeChangeLoggingSearchResults table tbody tr').length).to eq 3

      cols = ffj('#gradeChangeLoggingSearchResults table tbody tr:last td')
      expect(cols.size).to eq 8

      expect(cols[2].text).to eq "-"
      expect(cols[3].text).to eq "7"
      expect(cols[4].text).to eq @teacher.name
      expect(cols[5].text).to eq @student.name
      expect(cols[6].text).to eq @course.name
      expect(cols[7].text).to eq @assignment.title
    end

    it "should search by student name" do
      perform_autocomplete_search("#student_id-autocompleteField", @student.name)
      f('#loggingGradeChange button[name=gradeChange_submit]').click
      wait_for_ajaximations
      expect(ff('#gradeChangeLoggingSearchResults table tbody tr').length).to eq 3
    end

    it "should search by course id" do
      set_value f("#gradeChangeCourseSearch"), @course.id
      f('#loggingGradeChange button[name=gradeChange_submit]').click
      wait_for_ajaximations
      expect(ff('#gradeChangeLoggingSearchResults table tbody tr').length).to eq 3
    end

    it "should search by assignment id" do
      set_value f("#gradeChangeAssignmentSearch"), @assignment.id
      f('#loggingGradeChange button[name=gradeChange_submit]').click
      wait_for_ajaximations
      expect(ff('#gradeChangeLoggingSearchResults table tbody tr').length).to eq 3
    end
  end

  context "Course Logging" do
    it_should_behave_like "cassandra audit logs"

    before do
      course_with_teacher(course: @course, :user => user_with_pseudonym(:name => 'Teacher TestUser'))

      load_admin_tools_page
      click_view_tab "logging"
      change_log_type("Course")
    end

    it "should search by course name and show history" do
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
      f('#loggingCourse button[name=course_submit]').click
      wait_for_ajaximations

      expect(ff('#courseLoggingSearchResults table tbody tr').length).to eq @events.length
      cols = ffj('#courseLoggingSearchResults table tbody tr:last td')
      expect(cols.size).to eq 6

      expect(cols[2].text).to eq @teacher.name
      expect(cols[3].text).to eq "Updated"
      expect(cols[4].text).to eq "Manual"
      expect(cols[5].text).to eq "View Details"
    end

    it "should search by course id" do
      @course.name = "Course Updated"
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      set_value f("#course_id-autocompleteField"), @course.id
      f('#loggingCourse button[name=course_submit]').click
      wait_for_ajaximations
      cols = ffj('#courseLoggingSearchResults table tbody tr:last td')
      expect(cols.size).to eq 6
    end

    it "should find courses in any workflow state" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      @course.destroy

      autocomplete_value = perform_autocomplete_search("#course_id-autocompleteField", @course.name)
      expect(autocomplete_value).not_to be_nil

      f('#loggingCourse button[name=course_submit]').click
      wait_for_ajaximations

      cols = ffj('#courseLoggingSearchResults table tbody tr:last td')
      expect(cols.size).to eq 6
    end

    it "should show created event details" do
      # Simulate a new course
      course = Course.new
      course.name = @course.name
      @event = Auditors::Course.record_created(@course, @teacher, course.changes)

      show_event_details("Created")
      cols = ffj('.ui-dialog table:first tbody tr:first td')
      expect(cols.size).to eq 2
      expect(cols[0].text).to eq "Name"
      expect(cols[1].text).to eq @course.name
    end

    it "should show updated event details" do
      old_name = @course.name
      @course.name = "Course Updated"
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      show_event_details("Updated", old_name)
      items = ffj('.ui-dialog dl > dd')
      expect(items[4].text).to eq "Manual"
      expect(items[5].text).to eq "Updated"

      cols = ffj('.ui-dialog table:first tbody tr:first td')
      expect(cols.size).to eq 3
      expect(cols[0].text).to eq "Name"
      expect(cols[1].text).to eq old_name
      expect(cols[2].text).to eq @course.name
    end

    it "should show sis batch id if source is sis" do
      old_name = @course.name
      @course.name = "Course Updated"

      sis_batch = @account.root_account.sis_batches.create
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes, source: :sis, sis_batch: sis_batch)

      show_event_details("Updated", old_name)
      items = ffj('.ui-dialog dl > dd')
      expect(items[4].text).to eq "SIS"
      expect(items[5].text).to eq sis_batch.id.to_s
    end

    it "should show concluded event details" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      show_event_details("Concluded")
    end

    it "should show unconcluded event details" do
      @event = Auditors::Course.record_unconcluded(@course, @teacher)
      show_event_details("Unconcluded")
    end

    it "should show deleted event details" do
      @event = Auditors::Course.record_deleted(@course, @teacher)
      show_event_details("Deleted")
    end

    it "should show restored event details" do
      @event = Auditors::Course.record_restored(@course, @teacher)
      show_event_details("Restored")
    end

    it "should show published event details" do
      @event = Auditors::Course.record_published(@course, @teacher)
      show_event_details("Published")
    end

    it "should show copied_to event details" do
      @course, @copied_course = @course, course(active_course: true, course_name: "Copied Course")
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copied_course, @teacher)

      show_event_details("Copied To", @course.name, @to_event)
      expect(fj('.ui-dialog dl dd:last').text).to eq @copied_course.name
    end

    it "should show copied_from event details" do
      @course, @copied_course = @course, course(active_course: true, course_name: "Copied Course")
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copied_course, @teacher)

      show_event_details("Copied From", @copied_course.name, @from_event)
      expect(fj('.ui-dialog dl dd:last').text).to eq @course.name
    end

    it "should show reset_to event details" do
      @course, @reset_course = @course, course(active_course: true, course_name: "Reset Course")
      @from_event, @to_event = Auditors::Course.record_reset(@course, @reset_course, @teacher)

      show_event_details("Reset To", @course.name, @to_event)
      expect(fj('.ui-dialog dl dd:last').text).to eq @reset_course.name
    end

    it "should show copied_from event details" do
      @course, @reset_course = @course, course(active_course: true, course_name: "Reset Course")
      @from_event, @to_event = Auditors::Course.record_reset(@course, @reset_course, @teacher)

      show_event_details("Reset From", @reset_course.name, @from_event)
      expect(fj('.ui-dialog dl dd:last').text).to eq @course.name
    end
  end
end
