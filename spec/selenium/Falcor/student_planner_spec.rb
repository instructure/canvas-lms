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

require_relative '../common'
require_relative 'student_planner_page_object_model'

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true)
    @student1 = User.create!(name: 'Student 1')
    @course.enroll_student(@student1).accept!
  end

  before :each do
    user_session(@student1)
  end

  it "shows no due date assigned when no assignments are created", priority: "1", test_id: 3265570 do
    go_to_list_view
    validate_no_due_dates_assigned
  end

  it "navigates to the dashcard view from no due dates assigned page", priority: "1", test_id: 3281739 do
    go_to_list_view
    go_to_dashcard_view
    expect(f('.ic-DashboardCard__header-title')).to include_text(@course.name)
  end

  it "shows and navigates to announcements page from student planner", priority: "1", test_id: 3259302 do
    announcement = @course.announcements.create!(title: 'Hi there!', message: 'Announcement time!')
    go_to_list_view
    validate_object_displayed('Announcement')
    validate_link_to_url(announcement, 'discussion_topics')
  end

  context "assignments" do
    before :once do
      @assignment = @course.assignments.create({
                                                 name: 'Assignment 1',
                                                 due_at: Time.zone.now + 1.day,
                                                 submission_types: 'online_text_entry'
                                               })
    end

    it "shows and navigates to assignments page from student planner", priority: "1", test_id: 3259300 do
      go_to_list_view
      validate_object_displayed('Assignment')
      validate_link_to_url(@assignment, 'assignments')
    end

    it "shows submitted tag for assignments that have submissions", priority: "1", test_id: 3263151 do
      @assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "Assignment submitted")
      go_to_list_view

      # Student planner shows submitted assignments as completed. Expand to see the assignment
      expand_completed_item
      validate_pill('Submitted')
    end

    it "shows new grades tag for assignments that are graded", priority: "1", test_id: 3263152 do
      @assignment.grade_student(@student1, grade: 10, submission_comment: 'Good', grader: @teacher)
      go_to_list_view
      validate_pill('New Grades')
    end

    it "shows new feedback tag for assignments that has feedback", priority: "1", test_id: 3263154 do
      @assignment.grade_student(@student1, grade: 10, submission_comment: 'Good', grader: @teacher)
      go_to_list_view
      validate_pill('New Feedback')
    end

    it "shows missing tag for assignments with missing submissions", priority: "1", test_id: 3263153 do
      skip('WIP: scrolling fails intermittently')
      @assignment.due_at = Time.zone.now - 2.days
      @assignment.save!
      go_to_list_view
      scroll_to(f('.PlannerApp').find_element(:xpath, "//span[text()[contains(.,'Unnamed Course Assignment')]]"))
      validate_pill('Missing')
    end

    it "can follow course link to course", priority: "1", test_id: 3306198 do
      go_to_list_view
      element = fln(@course[:name].upcase, f('.PlannerApp'))
      expect_new_page_load do
        element.click
      end
      expect(driver).not_to contain_css('.StudentPlanner__Container')
    end
  end

  context "Graded discussion" do
    before :once do
      assignment = @course.assignments.create!(name: 'assignment',
                                               due_at: Time.zone.now.advance(days:2))
      @discussion = @course.discussion_topics.create!(title: 'Discussion 1',
                                                     message: 'Graded discussion',
                                                     assignment: assignment)
    end

    it "shows and navigates to graded discussions page from student planner", priority: "1", test_id: 3259301 do
      go_to_list_view
      validate_object_displayed('Discussion')
      validate_link_to_url(@discussion, 'discussion_topics')
    end

    it "shows new replies tag for discussion with new replies", priority: "1", test_id: 3284231 do
      @discussion.reply_from(user: @teacher, text: 'teacher reply')
      go_to_list_view
      validate_pill('New Replies')
    end
  end

  it "shows and navigates to ungraded discussions with todo dates from student planner", priority:"1", test_id: 3259305 do
    discussion = @course.discussion_topics.create!(user: @teacher, title: 'somebody topic title',
                                                   message: 'somebody topic message',
                                                   todo_date: Time.zone.now + 2.days)
    go_to_list_view
    validate_object_displayed('Discussion')
    validate_link_to_url(discussion, 'discussion_topics')
  end

  context "Quizzes" do
    before :once do
      @quiz = quiz_model(course: @course)
      @quiz.generate_quiz_data
      @quiz.due_at = Time.zone.now + 2.days
      @quiz.save!
    end

    it "shows and navigates to quizzes page from student planner", priority: "1", test_id: 3259303 do
      go_to_list_view
      validate_object_displayed('Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to graded surveys with due dates", priority: "1", test_id: 3282673 do
      @quiz.update(quiz_type: "graded_survey")
      go_to_list_view
      validate_object_displayed('Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to ungraded surveys with due dates", priority: "1", test_id: 3282674 do
      @quiz.update(quiz_type: "survey")
      go_to_list_view
      validate_object_displayed('Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to practice quizzes with due dates", priority: "1", test_id: 3284242 do
      @quiz.update(quiz_type: "practice_quiz")
      go_to_list_view
      validate_object_displayed('Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end
  end

  context "Create To Do Sidebar" do
    before :each do
      user_session(@student1)
    end

    it "opens the sidebar to creata a new To-Do item", priority: "1", test_id: 3263157 do
      go_to_list_view
      todo_modal_button.click
      expect(todo_save_button).to be_displayed
    end

    it "closes the sidebar tray with the 'X' button", priority: "1", test_id: 3263163 do
      go_to_list_view
      todo_modal_button.click
      expect(todo_sidebar_modal).to contain_jqcss("button:contains('Save')")
      fj("button:contains('Close')").click
      expect(f('body')).not_to contain_css("div[aria-label = 'Add To Do']")
    end

    it "adds text to the details field", priority: "1", test_id: 3263161 do
      go_to_list_view
      todo_modal_button.click
      todo_details.send_keys("https://imgs.xkcd.com/comics/code_quality_3.png")
      expect(todo_details[:value]).to include("https://imgs.xkcd.com/comics/code_quality_3.png")
    end

    it "adds text to the title field", priority: "1", test_id: 3263158 do
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = f('input', modal)
      element.send_keys("Title Text")
      expect(element[:value]).to include("Title Text")
    end

    it "adds a new date with the date picker", priority: "1", test_id: 3263159 do
      # sets up the date to compare against
      current_month = Time.zone.today.month
      test_month = Date::MONTHNAMES[(current_month + 1) % 12]
      test_year = Time.zone.today.year
      if current_month + 1 == 13
        test_year += 1
      end

      # opens the date picker
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = ff('input', modal)[1]
      element.click

      # selects a date (the 17th of next month) and verifies it is showing
      fj("button:contains('Next Month')").click
      fj("button:contains('17')").click
      expect(element[:value]).to eq("#{test_month} 17, #{test_year}")
      expect(modal).not_to include_text("Invalid date")
    end

    it "saves new ToDos properly", priority: "1", test_id: 3263162 do
      go_to_list_view
      todo_modal_button.click
      create_new_todo
      refresh_page

      # verifies that the new To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
    end

    it "edits a To Do", priority: "1", test_id: 3281714 do
      @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Title Text")
      go_to_list_view
      # Opens the To Do edit sidebar
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      fj("a:contains('Title Text')", todo_item).click

      # gives the To Do a new name and saves it
      modal = f("div[aria-label = 'Edit Title Text']")
      element = f('input', modal)
      element.send_keys(8.chr * 10)
      element.send_keys("New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("New Text")
      expect(todo_item).not_to include_text("Title Text")
    end

    it "deletes a To Do", priority: "1", test_id: 3281715 do
      @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Title Text")
      go_to_list_view
      expect(f('body')).not_to contain_jqcss("h2:contains('No Due Dates Assigned')")
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      fj("a:contains('Title Text')", todo_item).click
      fj("button:contains('Delete')").click
      refresh_page

      expect(fj("h2:contains('No Due Dates Assigned')")).to be_displayed
    end

    it "has courses in the course combo box", priority: "1", test_id: 3263160 do
      go_to_list_view
      todo_modal_button.click
      element = fj("select:contains('Optional: Add Course')")
      expect(fj("option:contains('Unnamed Course')", element)).to be
    end
  end

  it "shows and navigates to wiki pages with todo dates from student planner", priority: "1", test_id: 3259304 do
    page = @course.wiki_pages.create!(title: 'Page1', todo_date: Time.zone.now + 2.days)
    go_to_list_view
    validate_object_displayed('Page')
    validate_link_to_url(page, 'pages')
  end

  context "with existing assignment, open opportunities" do
    before :once do
      @course.assignments.create!(name: 'assignmentThatHasToBeDoneNow',
                                  description: 'This will take a long time',
                                  submission_types: 'online_text_entry',
                                  due_at: Time.zone.now - 2.days)
    end

    it "closes the opportunities dropdown", priority: "1", test_id: 3281711 do
      go_to_list_view
      open_opportunities_dropdown
      close_opportunities_dropdown
      expect(f('body')).not_to contain_jqcss("button[title='Close opportunities popover']")
    end

    it "links opportunity to the correct assignment page", priority: "1", test_id: 3281712 do
      go_to_list_view
      open_opportunities_dropdown
      parent = f('#opportunities_parent')
      fln('assignmentThatHasToBeDoneNow', parent).click
      expect(f('.description.user_content')).to include_text("This will take a long time")
    end

    it "dismisses assignment from opportunity dropdown", priority: "1", test_id: 3281713 do
      go_to_list_view
      open_opportunities_dropdown
      fj('button:contains("Dismiss assignmentThatHasToBeDoneNow")').click
      expect(f('#opportunities_parent')).not_to contain_jqcss('div:contains("assignmentThatHasToBeDoneNow")')
      expect(f('#opportunities_parent')).not_to contain_jqcss('button:contains("Dismiss assignmentThatHasToBeDoneNow")')
    end

    it "shows missing pill in the opportunities dropdown", priority: "1", test_id: 3281710 do
      go_to_list_view
      open_opportunities_dropdown
      expect(f('#opportunities_parent')).to contain_jqcss('span:contains("Missing")')
    end
  end

  context "History" do
    before :once do
      quiz = quiz_model(course: @course)
      quiz.generate_quiz_data
      quiz.due_at = Time.zone.now + 2.days
      quiz.save!
      Array.new(12){|n|n}.each do |i|
        @course.wiki_pages.create!(title: "Page#{i}", todo_date: Time.zone.now + (i-4).days)
        @course.assignments.create!(name: "assignment#{i}",
                                              due_at: Time.zone.now.advance(days:(i-4)))
        @course.discussion_topics.create!(user: @teacher, title: "topic#{i}",
                                                   message: "somebody topic message ##{i}",
                                                   todo_date: Time.zone.now + (i-4).days)
      end
    end

    it "loads more items at the bottom of the page", priority: "1", test_id: 3263149 do
      skip('functionality has changed need to rework ADMIN-276')
      go_to_list_view
      current_last_item = items_displayed.last
      current_items = items_displayed.count
      scroll_to(current_last_item)
      wait_for_spinner
      expect(items_displayed.count).to be > current_items
    end
  end

  it "completes and collapses item", priority: "1", test_id: 3263155 do
    @course.assignments.create!(name: 'assignment 1',
                                due_at: Time.zone.now + 2.days)
    go_to_list_view
    force_click('input[id*=Checkbox]')
    refresh_page
    wait_for_planner_load
    expect(f('.PlannerApp')).to contain_jqcss('span:contains("Show 1 completed item")')
  end
end
