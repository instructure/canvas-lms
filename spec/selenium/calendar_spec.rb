require File.expand_path(File.dirname(__FILE__) + '/common')

describe "calendar" do
  it_should_behave_like "in-process server selenium tests"

  context "student view" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should not show students the description of an assignment that is locked" do
      assignment = @course.assignments.create(:name => "locked assignment", :description => "this is secret", :due_at => Time.now + 2.days, :unlock_at => Time.now + 1.day)
      assignment.locked_for?(@user).should_not be_nil

      get "/calendar"

      wait_for_ajax_requests
      driver.find_element(:id, "event_assignment_#{assignment.id}").click
      wait_for_ajax_requests
      details = driver.find_element(:id, "event_details")
      details.find_element(:css, ".description").text.should_not match /secret/
      details.find_element(:css, ".lock_explanation").should
      include_text(I18n.t('messages.quiz_locked_at', "This quiz was locked %{at}.", :at => ""))
    end


    it "should allow flipping through months" do
      get "/calendar"

      month_name = driver.find_element(:css, ".calendar_month .month_name").text
      driver.find_element(:css, ".calendar_month .prev_month_link").click
      wait_for_ajax_requests
      driver.find_element(:css, ".calendar_month .month_name").text.should_not == month_name
      driver.find_element(:css, ".calendar_month .next_month_link").click
      wait_for_ajax_requests
      driver.find_element(:css, ".calendar_month .next_month_link").click
      wait_for_ajax_requests
      driver.find_element(:css, ".calendar_month .month_name").text.should_not == month_name
    end
  end

  context "teacher view" do
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should show the wiki sidebar when looking at the full event page" do
      get "/calendar"
      driver.find_element(:id, Time.now.strftime("day_%Y_%m_%d")).find_element(:css, ".calendar_day").click
      form = driver.find_element(:id, "edit_calendar_event_form")
      form.find_element(:css, "select.context_id option[value=\"course_#{@course.id}\"]").click
      expect_new_page_load { form.find_element(:css, ".more_options_link").click }
      keep_trying_until { driver.find_element(:id, "editor_tabs").should be_displayed }
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

      get "/calendar"
      wait_for_ajax_requests

      #verify both assignments are visible
      unless is_checked("#group_course_#{first_course.id}")
        driver.find_element(:id, "group_course_#{first_course.id}").click
      end
      unless is_checked("#group_course_#{second_course.id}")
        driver.find_element(:id, "group_course_#{second_course.id}").click
      end
      date_holder_id = "day_#{due_date.year}_#{due_date.strftime('%m')}_#{due_date.strftime('%d')}"
      driver.find_element(:css, "##{date_holder_id} #event_assignment_#{first_assignment.id}").should be_displayed
      driver.find_element(:css, "##{date_holder_id} #event_assignment_#{second_assignment.id}").should be_displayed

      #verify first assignment is visible and not the second
      driver.find_element(:id, "group_course_#{second_course.id}").click
      driver.find_element(:css, "##{date_holder_id} #event_assignment_#{first_assignment.id}").should be_displayed
      driver.find_element(:css, "##{date_holder_id} #event_assignment_#{second_assignment.id}").should_not be_displayed
    end

    it "should allow editing event details repeatedly" do
      calendar_event_model(:title => "ev", :start_at => "2012-04-02")
      @event.all_day.should be_true

      get "/courses/#{@course.id}/calendar_events/#{@event.id}"
      f("a.edit_calendar_event_link").click
      replace_content(f("input#calendar_event_title"), "edit1")
      submit_form("form#edit_calendar_event_form")
      wait_for_ajax_requests

      keep_trying_until { fj("a.edit_calendar_event_link").should be_displayed } #using fj to bypass selenium cache
      fj("a.edit_calendar_event_link").click
      replace_content(f("input[name=start_date]"), "2012-04-05")
      replace_content(f("input#calendar_event_title"), "edit2")
      submit_form("form#edit_calendar_event_form")
      wait_for_ajax_requests

      @event.reload
      @event.title.should == "edit2"
      @event.all_day.should be_true
      @event.start_at.should == Time.zone.parse("2012-04-05")
    end
  end
end
