require File.expand_path(File.dirname(__FILE__) + '/common')

describe "calendar" do
  it_should_behave_like "in-process server selenium tests"

  def go_to_calendar
    get "/calendar"
    wait_for_ajaximations
  end

  context "teacher view" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should create an event" do
      new_event_name = 'new event'
      go_to_calendar

      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day").click
      replace_content(f('#calendar_event_title'), new_event_name)
      submit_form('#edit_calendar_event_form')
      wait_for_ajaximations
      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day").should include_text(new_event_name)
      CalendarEvent.find_by_title(new_event_name).should be_present
    end

    it "should edit an event" do
      edit_name = 'edited cal title'
      calendar_event_model(:title => "new event", :start_at => Time.now)
      go_to_calendar

      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day .calendar_event").click
      f('.edit_event_link').click
      replace_content(f('#calendar_event_title'), edit_name)
      submit_form('#edit_calendar_event_form')
      wait_for_ajaximations
      CalendarEvent.find_by_title(edit_name).should be_present
    end

    it "should delete an event" do
      event_title = 'new event'
      calendar_event_model(:title => event_title, :start_at => Time.now)
      go_to_calendar

      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day .calendar_event").click
      f('.delete_event_link').click
      keep_trying_until do
        driver.switch_to.alert.should_not be nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day").should_not include_text(event_title)
      CalendarEvent.find_by_title(event_title).workflow_state.should == 'deleted'
    end

    it "should view the full details of an event" do
      event_title = 'new event'
      calendar_event_model(:title => event_title, :start_at => Time.now)
      go_to_calendar

      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day .calendar_event").click
      expect_new_page_load { f('.view_event_link').click }
      f('#full_calendar_event .title').should include_text(event_title)
    end

    it "should drag and drop an event" do
      pending('drag and drop not working correctly')
      event_title = 'new event'
      calendar_event_model(:title => event_title, :start_at => Time.now)
      go_to_calendar

      event_date = f("##{Time.now.strftime("day_%Y_%m_%d")}").attribute(:id)
      parsed_event_date = Date.parse(event_date[4..13].gsub('_', '/'))
      driver.action.drag_and_drop_by(f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day .calendar_event"), f("##{(parsed_event_date - 1.day).strftime("day_%Y_%m_%d")} .calendar_day")).perform
      wait_for_ajaximations
      f("##{(parsed_event_date - 1.day).strftime("day_%Y_%m_%d")} .calendar_day").should include_text(event_title)
    end

    it "should view undated events" do
      event_title = 'undated event'
      calendar_event_model(:title => event_title)
      go_to_calendar

      undated_link = f('.show_undated_link')
      keep_trying_until { undated_link.text.should == 'show 1 undated events' }
      undated_link.click
      wait_for_ajaximations
      f('.calendar_undated').should include_text(event_title)
    end

    it "should validate the ical feed display" do
      go_to_calendar

      f('.calendar_feed_link').click
      f('#calendar_feed_box').should be_displayed
    end

    it "should show the wiki sidebar when looking at the full event page" do
      go_to_calendar

      f("##{Time.now.strftime("day_%Y_%m_%d")} .calendar_day").click
      click_option('#edit_calendar_event_form .context_id', "course_#{@course.id}", :value)
      expect_new_page_load { f("#edit_calendar_event_form .more_options_link").click }
      keep_trying_until { f("#editor_tabs").should be_displayed }
    end

    it "should only display events for selected course" do
      @course.name = 'first course'
      @course.save!
      due_date = Time.now.utc
      first_assignment = @course.assignments.create(:name => 'first assignment', :due_at => due_date)
      first_course = @course
      student = @user
      second_course = course_model({:name => 'second course'})
      second_course.offer!
      enrollment = second_course.enroll_student(student)
      enrollment.workflow_state = 'active'
      enrollment.save!
      second_course.reload
      second_assignment = second_course.assignments.create(:name => 'second assignment', :due_at => due_date)
      go_to_calendar

      #verify both assignments are visible
      unless is_checked("#group_course_#{first_course.id}")
        f("#group_course_#{first_course.id}").click
      end
      unless is_checked("#group_course_#{second_course.id}")
        f("#group_course_#{second_course.id}").click
      end
      date_holder_id = "day_#{due_date.year}_#{due_date.strftime('%m')}_#{due_date.strftime('%d')}"
      f("##{date_holder_id} #event_assignment_#{first_assignment.id}").should be_displayed
      f("##{date_holder_id} #event_assignment_#{second_assignment.id}").should be_displayed

      #verify first assignment is visible and not the second
      f("#group_course_#{second_course.id}").click
      f("##{date_holder_id} #event_assignment_#{first_assignment.id}").should be_displayed
      f("##{date_holder_id} #event_assignment_#{second_assignment.id}").should_not be_displayed
    end

    it "should allow editing event details repeatedly" do
      calendar_event_model(:title => "ev", :start_at => "2012-04-02")
      @event.all_day.should be_true

      get "/courses/#{@course.id}/calendar_events/#{@event.id}"
      f(".edit_calendar_event_link").click
      replace_content(f("#calendar_event_title"), "edit1")
      submit_form("#edit_calendar_event_form")
      wait_for_ajax_requests

      keep_trying_until { fj(".edit_calendar_event_link").should be_displayed } #using fj to bypass selenium cache
      fj(".edit_calendar_event_link").click
      replace_content(f("input[name=start_date]"), "2012-04-05")
      replace_content(f("#calendar_event_title"), "edit2")
      submit_form("#edit_calendar_event_form")
      wait_for_ajax_requests

      @event.reload
      @event.title.should == "edit2"
      @event.all_day.should be_true
      @event.start_at.should == Time.zone.parse("2012-04-05")
    end
  end

  context "student view" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should not show students the description of an assignment that is locked" do
      assignment = @course.assignments.create(:name => "locked assignment", :description => "this is secret", :due_at => Time.now + 2.days, :unlock_at => Time.now + 1.day)
      assignment.locked_for?(@user).should_not be_nil
      go_to_calendar

      f("#event_assignment_#{assignment.id}").click
      wait_for_ajax_requests
      details = f("#event_details")
      details.find_element(:css, ".description").should_not include_text('secret')
      details.find_element(:css, ".lock_explanation").should include_text("This assignment is locked")
    end

    it "should allow flipping through months" do
      go_to_calendar

      month_name = f(".calendar_month .month_name").text
      f(".calendar_month .prev_month_link").click
      wait_for_ajax_requests
      f(".calendar_month .month_name").text.should_not == month_name
      f(".calendar_month .next_month_link").click
      wait_for_ajax_requests
      f(".calendar_month .next_month_link").click
      wait_for_ajax_requests
      f(".calendar_month .month_name").text.should_not == month_name
    end

    it "should navigate the mini calendar" do
      go_to_calendar

      current_month_name = f('.mini-cal-month-and-year .month_name').text
      f('.mini-cal-header .next_month_link').click
      f('.mini-cal-month-and-year .month_name').text.should_not == current_month_name
      f('.mini-cal-header .prev_month_link').click
      fj('.mini-cal-month-and-year .month_name').text.should == current_month_name #fj to avoid selenium caching
    end

    it "should navigate the main calendar when the mini calendar is navigated" do
      go_to_calendar

      f('.mini-cal-header .next_month_link').click
      ff('.mini_calendar_day .day_number')[10].click
      keep_trying_until { f('.calendar_month .month_name').text.should == f('.mini-cal-month-and-year .month_name').text }
    end
  end
end
