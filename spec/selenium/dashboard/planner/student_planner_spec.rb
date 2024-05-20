# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/student_planner_page"
require_relative "../../admin/pages/student_context_tray_page"
require_relative "../../assignments/page_objects/assignment_page"

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    course_with_teacher(active_all: true, new_user: true, user_name: "PlannerTeacher", course_name: "Planner Course")
    @student1 = User.create!(name: "Student 1")
    @course.enroll_student(@student1).accept!
  end

  before do
    user_session(@student1)
  end

  it "shows no due date assigned when no assignments are created.", priority: "1" do
    go_to_list_view
    validate_no_due_dates_assigned
  end

  it "navigates to the dashcard view from no due dates assigned page.", priority: "1" do
    go_to_list_view
    switch_to_dashcard_view

    expect(dashboard_card_container).to contain_css("[aria-label='#{@course.name}']")
    expect(dashboard_card_header_content).to contain_css("h3[title='#{@course.name}']")
  end

  it "shows and navigates to announcements page from student planner", priority: "1" do
    announcement = @course.announcements.create!(title: "Hi there!", message: "Announcement time!")
    go_to_list_view
    validate_object_displayed(@course.name, "Announcement")
    validate_link_to_url(announcement, "discussion_topics")
  end

  it "shows and navigates to the calendar events page", priority: "1" do
    event = CalendarEvent.new(title: "New event", start_at: 1.minute.from_now)
    event.context = @course
    event.save!
    go_to_list_view
    validate_object_displayed(@course.name, "Calendar Event")
    validate_link_to_calendar(event)
  end

  it "shows course images", priority: "1" do
    @course_root = Folder.root_folders(@course).first
    @course_attachment = @course_root.attachments.create!(context: @course,
                                                          uploaded_data: jpeg_data_frd,
                                                          filename: "course.jpg",
                                                          display_name: "course.jpg")
    @course.image_id = @course_attachment.id
    @course.save!
    @course.announcements.create!(title: "Hi there!", message: "Announcement time!")
    go_to_list_view
    validate_object_displayed(@course.name, "Announcement")
    elem = f("a[href='/courses/#{@course.id}']")
    url = driver.current_url
    # validate the background image url
    expect(elem[:style])
      .to include("#{url}courses/#{@course.id}/files/#{@course_attachment.id}/download?verifier=#{@course_attachment.uuid}")
  end

  context "responsive layout" do
    it "changes layout on browser resize" do
      go_to_list_view

      expect(f(".large.ic-Dashboard-header__layout")).to be_present
      expect(f(".large.PlannerApp")).to be_present

      dimension = driver.manage.window.size
      driver.manage.window.resize_to(800, dimension.height)
      expect(f(".medium.ic-Dashboard-header__layout")).to be_present
      expect(f(".medium.PlannerApp")).to be_present

      driver.manage.window.resize_to(500, dimension.height)
      expect(f(".small.ic-Dashboard-header__layout")).to be_present
      expect(f(".small.PlannerApp")).to be_present
    end
  end

  context "wiki_pages" do
    before :once do
      @wiki_page = @course.wiki_pages.create!(title: "Page1", todo_date: DateTime.current.change({ min: 5 }) + 2.days)
    end

    it "shows the date in the index page" do
      get "/courses/#{@course.id}/pages/"
      wait_for_ajaximations
      expect(f('a[data-sort-field="todo_date"]')).to be_displayed
      expect(f("tbody.collectionViewItems")).to include_text(format_time_for_view(@wiki_page.todo_date, :short))
    end

    it "shows the date in the show page" do
      get "/courses/#{@course.id}/pages/#{@wiki_page.id}/"
      expect(f(".show-content")).to include_text(format_time_for_view(@wiki_page.todo_date, :short))
    end
  end

  context "Quizzes" do
    before :once do
      @quiz = quiz_model(course: @course)
      @quiz.generate_quiz_data
      @quiz.due_at = 2.days.from_now
      @quiz.save!
    end

    it "shows and navigates to quizzes page from student planner", priority: "1" do
      go_to_list_view
      validate_object_displayed(@course.name, "Quiz")
      validate_link_to_url(@quiz, "quizzes")
    end

    it "shows and navigates to graded surveys with due dates", priority: "1" do
      @quiz.update(quiz_type: "graded_survey")
      go_to_list_view
      validate_object_displayed(@course.name, "Quiz")
      validate_link_to_url(@quiz, "quizzes")
    end

    it "shows and navigates to ungraded surveys with due dates", priority: "1" do
      @quiz.update(quiz_type: "survey")
      go_to_list_view
      validate_object_displayed(@course.name, "Quiz")
      validate_link_to_url(@quiz, "quizzes")
    end

    it "shows and navigates to practice quizzes with due dates", priority: "1" do
      @quiz.update(quiz_type: "practice_quiz")
      go_to_list_view
      validate_object_displayed(@course.name, "Quiz")
      validate_link_to_url(@quiz, "quizzes")
    end
  end

  context "Peer Reviews" do
    before :once do
      @reviewee = user_factory(active_all: true)
      @course.enroll_student(@reviewee).accept!
      @assignment = @course.assignments.create({
                                                 name: "Peer Review Assignment",
                                                 due_at: 1.day.from_now,
                                                 peer_reviews: true,
                                                 automatic_peer_reviews: false,
                                                 submission_types: "online_text_entry"
                                               })
      @assignment.assign_peer_review(@student1, @reviewee)
    end

    it "shows peer review submissions" do
      go_to_list_view

      validate_object_displayed(@course.name, "Peer Review")
      expect(list_view_planner_item("Planner Course Peer Review")).to contain_css(peer_review_icon_selector)
      expect(list_view_planner_item("Planner Course Peer Review")).to contain_jqcss(peer_review_reminder_selector)
      expect(list_view_planner_item("Planner Course Assignment")).not_to contain_css(peer_review_icon_selector)
    end

    it "navigates to peer review submission when clicked" do
      go_to_list_view
      click_peer_review(@course.name, @assignment.name)

      expect(driver.current_url).to include "courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
    end

    it "marks peer review as completed" do
      go_to_list_view
      mark_peer_review_as_complete(@course.name)

      expect(peer_review_item(@course.name)).to contain_jqcss("label:contains('Peer Review #{@assignment.name} is marked as done.')")
    end
  end

  context "Create To Do Sidebar" do
    include StudentContextTray

    before do
      user_session(@student1)
    end

    it "opens the sidebar to create a new To-Do item.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      expect(todo_save_button).to be_displayed
    end

    it "closes the sidebar tray with the 'X' button.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      expect(todo_sidebar_modal).to contain_jqcss("button:contains('Save')")
      fj("button:contains('Close')").click
      expect(f("body")).not_to contain_css("[aria-label = 'Add To Do']")
    end

    it "adds text to the details field.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      todo_details.send_keys("https://imgs.xkcd.com/comics/code_quality_3.png\n")
      expect(todo_details[:value]).to include("https://imgs.xkcd.com/comics/code_quality_3.png")
    end

    it "adds text to the title field.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = f("input", modal)
      element.send_keys("Title Text")
      expect(element[:value]).to include("Title Text")
    end

    it "adds a new date with the date picker.", priority: "1" do
      # sets up the date to compare against
      current_month = Time.zone.today.month
      test_month = Date::MONTHNAMES[(current_month % 12) + 1]
      test_year = Time.zone.today.year
      if current_month == 12
        test_year += 1
      end

      # opens the date picker
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = ff("input", modal)[1]
      element.click

      # selects a date (the 17th of next month) and verifies it is showing
      fj("button:contains('Next Month')").click
      fj("button:contains('17')").click
      expect(element[:value]).to eq("#{test_month} 17, #{test_year}")
      expect(modal).not_to include_text("Invalid date")
    end

    it "saves new ToDos properly.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      create_new_todo
      refresh_page

      # verifies that the new To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      expect(f("body")).not_to contain_css(todo_sidebar_modal_selector)
    end

    it "edits a To Do", priority: "1" do
      @student1.planner_notes.create!(todo_date: Time.zone.now, title: "Title Text")
      go_to_list_view
      # Opens the To Do edit sidebar
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      click_item_button("Title Text")

      # gives the To Do a new name and saves it
      title_input("Title Text").send_keys([:control, "a"], :backspace, "New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("New Text")
      expect(todo_item).not_to include_text("Title Text")
      expect(f("body")).not_to contain_css(todo_sidebar_modal_selector)
    end

    it "edits a completed To Do.", priority: "1" do
      # The following student planner is added to avoid the `beginning of to-do history` image
      # which makes the page to scroll and causes flakiness
      @student1.planner_notes.create!(todo_date: 1.day.ago, title: "Past Title")

      @student1.planner_notes.create!(todo_date: 1.day.from_now, title: "Title Text")
      go_to_list_view

      # complete it
      f(".planner-item label").click
      expect(f("input[type=checkbox]:checked")).to be_displayed

      # Opens the To Do edit sidebar
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      click_item_button("Title Text")

      # gives the To Do a new name and saves it
      element = title_input("Title Text")
      replace_content(element, "New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("New Text")

      # and that it is still complete
      expect(f("input[type=checkbox]:checked")).to be_displayed
    end

    it "deletes a To Do", priority: "1" do
      @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Title Text")
      go_to_list_view
      expect(f("body")).not_to contain_jqcss("h2:contains('No Due Dates Assigned')")
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      click_item_button("Title Text")
      fj("button:contains('Delete')").click
      alert = driver.switch_to.alert
      expect(alert.text).to eq("Are you sure you want to delete this planner item?")
      alert.accept
      expect(f("body")).not_to contain_css(todo_sidebar_modal_selector)
      refresh_page

      expect(fj("h2:contains('No Due Dates Assigned')")).to be_displayed
    end

    it "groups the to-do item with other course items", priority: "1" do
      @assignment = @course.assignments.create({
                                                 name: "Assignment 1",
                                                 due_at: 1.day.from_now,
                                                 submission_types: "online_text_entry"
                                               })
      @student1.planner_notes.create!(todo_date: 1.day.from_now, title: "Title Text", course_id: @course.id)
      go_to_list_view
      course_group = f("ol", planner_app_div)
      group_items = ff("li", course_group)
      expect(group_items.count).to eq(2)
    end

    it "allows date of a to-do item to be edited.", priority: "1" do
      view_todo_item

      date = format_date_for_view(Time.zone.now, :long).split
      day =
        if date[1] == "15"
          date[1] = "20"
          date[0] + " 20, " + date[2]
        else
          date[1] = "15"
          date[0] + " 15, " + date[2]
        end

      date_input = ff("input", @modal)[1]

      keep_trying_until(10) do
        replace_content(date_input, day)
        expect(element_value_for_attr(date_input, "value")).to eq(day)
      end

      # date input needs to be blurred in order to trigger state update
      date_input.send_keys(:tab)

      todo_save_button.click
      @student_to_do.reload
      expect(format_date_for_view(@student_to_do.todo_date, :long)).to eq(day)
    end

    it "adds date and time to a to-do item.", priority: "1" do
      skip "FOO-3821 cf. https://github.com/instructure/instructure-ui/issues/1276"
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = ff("input", modal)[1]
      element.click
      fj("button:contains('15')").click
      title_input.send_keys("the title")
      time_input.click
      fj("span[role=option]:contains('9:00 AM')").click
      todo_save_button.click
      expect(ff(".planner-item").last).to include_text "DUE: 9:00 AM"
    end

    it "updates the sidebar when clicking on mutiple to-do items", priority: "1" do
      student_to_do2 = @student1.planner_notes.create!(todo_date: 5.minutes.from_now,
                                                       title: "Student to do 2")
      view_todo_item
      modal = todo_sidebar_modal(@student_to_do.title)
      title_input = f("input", modal)
      course_name_dropdown = f("#to-do-item-course-select", modal)

      expect(title_input[:value]).to eq(@student_to_do.title)
      expect(course_name_dropdown[:value]).to eq("#{@course.name} - #{@course.short_name}")

      click_item_button(student_to_do2.title)
      expect(title_input[:value]).to eq(student_to_do2.title)
      expect(course_name_dropdown[:value]).to eq("Optional: Add Course")
    end

    it "allows editing the course of a to-do item", priority: "1" do
      view_todo_item
      attempt = 0
      max_attempts = 3
      begin
        attempt += 1
        todo_tray_select_course_from_dropdown
      rescue => e
        if attempt < max_attempts
          puts "\t Attempt #{attempt} failed! Retrying..."
          sleep 0.5
          retry
        end
        raise Selenium::WebDriver::Error::ElementNotInteractableError, e.message.to_s
      end

      todo_save_button.click
      @student_to_do.reload
      expect(@student_to_do.course_id).to be_nil
    end

    it "has courses in the course combo box.", priority: "1" do
      go_to_list_view
      todo_modal_button.click
      todo_tray_course_selector.click
      expect(todo_tray_course_suggestions).to include_text @course.name
    end

    it "ensures time zones with offsets higher than UTC update the planner items" do
      planner_note = @student1.planner_notes.create!(todo_date: 1.day.from_now, title: "A Planner Note")
      @student1.update!(time_zone: "Minsk")
      go_to_list_view
      click_item_button(planner_note.title)
      modal = todo_sidebar_modal(planner_note.title)
      expected_todo_date = ff("input", modal)[1][:value]
      actual_todo_date = format_date_for_view(planner_note.todo_date.in_time_zone(@student1.time_zone), :long)
      expect(expected_todo_date).to eq actual_todo_date
    end
  end

  it "shows and navigates to wiki pages with todo dates from student planner", priority: "1" do
    page = @course.wiki_pages.create!(title: "Page1", todo_date: 2.days.from_now)
    go_to_list_view
    validate_object_displayed(@course.name, "Page")
    validate_link_to_url(page, "pages")
  end

  context "with existing assignment, open opportunities" do
    before :once do
      @assignment_opportunity = @course.assignments.create!(name: "assignmentThatHasToBeDoneNow",
                                                            description: "This will take a long time",
                                                            submission_types: "online_text_entry",
                                                            due_at: 2.days.ago,
                                                            points_possible: 132)
    end

    it "closes the opportunities dropdown.", priority: "1" do
      # Adding this today assignment only so that an alert doesn't come up saying Nothing is Due Today
      # It interferes with the dropdown in Jenkins
      @course.assignments.create!(name: "assignment due today",
                                  description: "we need this so we dont get the popup",
                                  submission_types: "online_text_entry",
                                  due_at: Time.zone.now)
      go_to_list_view
      open_opportunities_dropdown
      close_opportunities_dropdown

      expect(f("body")).not_to contain_jqcss(close_opportunities_selector)
    end

    it "links opportunity to the correct assignment page.", priority: "1" do
      # Adding this today assignment only so that an alert doesn't come up saying Nothing is Due Today
      # It interferes with the dropdown in Jenkins
      @course.assignments.create!(name: "assignment due today",
                                  description: "we need this so we dont get the popup",
                                  submission_types: "online_text_entry",
                                  due_at: Time.zone.now)
      go_to_list_view
      open_opportunities_dropdown

      expect(flnpt(@assignment_opportunity.name, opportunities_parent)).to be_present

      click_opportunity(@assignment_opportunity.name)

      expect(driver.current_url).to include "courses/#{@course.id}/assignments/#{@assignment_opportunity.id}"
      expect(AssignmentPage.assignment_description.text).to eq @assignment_opportunity.description
    end

    it "does not show points possible when restrict_quantitative_data is true" do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
      @course.restrict_quantitative_data = true
      @course.save!

      go_to_list_view
      open_opportunities_dropdown
      expect(f("body")).not_to contain_jqcss(".Opportunity-styles__points:contains('132')")
    end

    it "dismisses assignment from opportunity dropdown.", priority: "1" do
      # Adding this today assignment only so that an alert doesn't come up saying Nothing is Due Today
      # It interferes with the dropdown in Jenkins
      @course.assignments.create!(name: "assignment due today",
                                  description: "we need this so we dont get the popup",
                                  submission_types: "online_text_entry",
                                  due_at: Time.zone.now)

      go_to_list_view
      open_opportunities_dropdown

      # There is some latency when clicking dismissing an opportunity.  This makes sure the buttons are clicked and we
      # waiting for the items to be available.  There is a warning on this one, but example provided instead does not
      # work in this circumstance.

      keep_trying_for_attempt_times(attempts: 5, sleep_interval: 0.5) do
        dismiss_opportunity_button(@assignment_opportunity.name).click
        wait_for_no_such_element { opportunity_item_selector(@assignment_opportunity.name) }
        expect(opportunities_parent).not_to contain_jqcss(dismiss_opportunity_button_selector(@assignment_opportunity.name))
      end
    end

    it "shows missing pill in the opportunities dropdown.", priority: "1" do
      go_to_list_view
      open_opportunities_dropdown
      expect(opportunities_parent).to contain_jqcss('span:contains("Missing")')
    end
  end

  context "with new activity button" do
    before :once do
      @old, @older, @oldest = new_activities_in_the_past
      @future_discussion = graded_discussion_in_the_future
    end

    before do
      user_session(@student1)
    end

    it "collapses an item when marked as complete", priority: "1" do
      go_to_list_view

      planner_item_status_checkbox("Discussion", @future_discussion.title).click
      refresh_page
      expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
    end
  end

  context "teacher in a course" do
    before :once do
      @teacher1 = User.create!(name: "teacher")
      @course.enroll_teacher(@teacher1).accept!
    end

    before do
      user_session(@teacher1)
    end

    it "shows correct default time in a wiki page" do
      Timecop.freeze(Time.zone.today) do
        @wiki = @course.wiki_pages.create!(title: "Default Time Wiki Page")
        get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
        f("#student_planner_checkbox").click
        wait_for_ajaximations
        replace_content(f('input[name="student_todo_at"]'), format_date_for_view(Time.zone.now).to_s, tab_out: true)
        expect_new_page_load { fj('button:contains("Save")').click }
        get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
        expect(get_value('input[name="student_todo_at"]')).to eq format_date_for_view(Time.zone.today, "%b %-d, %Y, 11:59 PM")
      end
    end

    it "allows account admins with content management rights to add todo dates" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      @course.root_account.disable_feature!(:granular_permissions_manage_course_content)
      @wiki = @course.wiki_pages.create!(title: "Default Time Wiki Page")
      admin = account_admin_user_with_role_changes(role_changes: { manage_courses: false })
      user_session(admin)

      expect(@course.grants_right?(admin, :manage)).to be false # sanity check
      expect(@course.grants_right?(admin, :manage_content)).to be true

      get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
      f("#student_planner_checkbox").click
      wait_for_ajaximations
      replace_content(f('input[name="student_todo_at"]'), format_date_for_view(Time.zone.now).to_s, tab_out: true)
      expect_new_page_load { fj('button:contains("Save")').click }
      expect(@wiki.reload.todo_date).to be_present
    end

    it "allows account admins with content management rights to add todo dates (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @course.root_account.enable_feature!(:granular_permissions_manage_course_content)
      @wiki = @course.wiki_pages.create!(title: "Default Time Wiki Page")
      admin = account_admin_user
      user_session(admin)

      expect(@course.grants_right?(admin, :manage)).to be true
      expect(@course.grants_right?(admin, :manage_course_content_edit)).to be true

      get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
      f("#student_planner_checkbox").click
      replace_content(f('input[name="student_todo_at"]'), format_date_for_view(Time.zone.now).to_s, tab_out: true)
      expect_new_page_load { fj('button:contains("Save")').click }
      expect(@wiki.reload.todo_date).to be_present
    end

    it "shows correct default time in an ungraded discussion" do
      Timecop.freeze(Time.zone.today) do
        @discussion = @course.discussion_topics.create!(title: "Default Time Discussion", message: "here is a message", user: @teacher)
        get("/courses/#{@course.id}/discussion_topics/#{@discussion.id}/edit")
        f("#allow_todo_date").click
        wait_for_ajaximations
        replace_content(f('input[name="todo_date"]'), format_date_for_view(Time.zone.now).to_s, tab_out: true)
        expect_new_page_load { submit_form(".form-actions") }
        get("/courses/#{@course.id}/discussion_topics/#{@discussion.id}/edit")
        expect(get_value('input[name="todo_date"]')).to eq format_date_for_view(Time.zone.today, "%b %-d, %Y, 11:59 PM")
      end
    end
  end

  context "My Grades tray" do
    before :once do
      @course2 = course_factory(active_all: true)
      @course2.enroll_student(@student1).accept!
      @course2_assignment = @course2.assignments.create!(name: "Course 2 Assignment", points_possible: 20, submission_types: "online_text_entry")
      @course2_assignment.grade_student(@student1, grader: @teacher, score: 14)
    end

    it "shows effective grades for student courses" do
      user_session(@student1)
      go_to_list_view
      fj("button:contains('Show My Grades')").click
      shown_grades = ff("[data-testid='my-grades-score']")
      expect(shown_grades.map(&:text)).to eq ["No Grade", "70.00%"]
    end

    it "shows letter grades when user is quantitative data restricted" do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
      @course2.restrict_quantitative_data = true
      @course2.save!

      user_session(@student1)
      go_to_list_view
      fj("button:contains('Show My Grades')").click
      shown_grades = ff("[data-testid='my-grades-score']")
      expect(shown_grades.map(&:text)).to eq ["No Grade", "C-"]
    end
  end

  context "interaction with ToDoSidebar" do
    before do
      user_session(@student1)
      @todo_item = @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Some Todo Item")
    end

    it "completes planner item when dismissed from card view sidebar", prirority: "1" do
      go_to_dashcard_view
      # dismiss the item
      dismiss_todo_item(@todo_item.title)

      switch_to_list_view
      expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
    end

    it "completes planner item when dismissed from a course sidebar" do
      get "/courses/#{@course.id}"
      # dismiss the item
      dismiss_todo_item(@todo_item.title)

      go_to_list_view
      expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
    end
  end

  context "with restrict_quantitative_data ff" do
    before do
      @course.account.enable_feature!(:restrict_quantitative_data)

      @course.assignments.create!(name: "Assignment 1",
                                  points_possible: 10,
                                  due_at: 2.days.from_now)
      @course.assignments.create!(name: "Assignment 2",
                                  points_possible: 15,
                                  due_at: 2.days.from_now)
    end

    describe "with setting turned off" do
      it "should show points" do
        go_to_dashcard_view

        expect(ff("ul[data-testid='ToDoSidebarItem__InformationRow']")[0].text.start_with?("10 points")).to be_truthy
        expect(ff("ul[data-testid='ToDoSidebarItem__InformationRow']")[1].text.start_with?("15 points")).to be_truthy
      end
    end

    describe "with setting turned on" do
      before do
        @course.settings = @course.settings.merge(restrict_quantitative_data: true)
        @course.save!
      end

      it "should not show points" do
        go_to_dashcard_view

        expect(ff("ul[data-testid='ToDoSidebarItem__InformationRow']")[0].text.start_with?("10 points")).to be_falsey
        expect(ff("ul[data-testid='ToDoSidebarItem__InformationRow']")[1].text.start_with?("15 points")).to be_falsey
      end
    end
  end
end
