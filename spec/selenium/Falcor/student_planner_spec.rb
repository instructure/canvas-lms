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

  it "shows no due date assigned when no assignments are created.", priority: "1", test_id: 3265570 do
    go_to_list_view
    validate_no_due_dates_assigned
  end

  it "navigates to the dashcard view from no due dates assigned page.", priority: "1", test_id: 3281739 do
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

  it "shows and navigates to the calendar events page", priority: "1", test_id: 3488530 do
    event = CalendarEvent.new(title: "New event", start_at: 1.minute.from_now)
    event.context = @course
    event.save!
    go_to_list_view
    validate_object_displayed('Calendar Event')
    validate_link_to_url(event, 'calendar_events')
  end

  it "shows course images when the feature is enabled", priority: "1", test_id: 3306206 do
    Account.default.enable_feature!(:course_card_images)
    @course_root = Folder.root_folders(@course).first
    @course_attachment = @course_root.attachments.create!(:context => @course,
                                                          :uploaded_data => jpeg_data_frd, :filename => 'course.jpg',
                                                          :display_name => 'course.jpg')
    @course.image_id = @course_attachment.id
    @course.save!
    @course.announcements.create!(title: 'Hi there!', message: 'Announcement time!')
    go_to_list_view
    validate_object_displayed('Announcement')
    elem = f("a[href='/courses/#{@course.id}']")
    url = driver.current_url
    # validate the background image url
    expect(elem[:style]).
      to include("#{url}courses/#{@course.id}/files/#{@course_attachment.id}/download?verifier=#{@course_attachment.uuid}")

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

    it "navigates to the assignment submissions page when they are submitted." do
      @assignment.submit_homework(@student1, submission_type: "online_text_entry",
                                  body: "Assignment submitted")
      go_to_list_view
      fj("button:contains('Show 1 completed item')").click
      validate_link_to_submissions(@assignment, @student1,'assignments')
    end

    it "enables the checkbox when an assignment is completed", priority: "1", test_id: 3306201 do
      @assignment.submit_homework(@student1, submission_type: "online_text_entry",
                                  body: "Assignment submitted")
      go_to_list_view
      expect(f('.PlannerApp')).to contain_jqcss('span:contains("Show 1 completed item")')
    end

    it "shows submitted tag for assignments that have submissions", priority: "1", test_id: 3263151 do
      @assignment.submit_homework(@student1, submission_type: "online_text_entry", body: "Assignment submitted")
      go_to_list_view

      # Student planner shows submitted assignments as completed. Expand to see the assignment
      expand_completed_item
      validate_pill('Submitted')
    end

    it "shows new grades tag for assignments that are graded", priority: "1", test_id: 3263152 do
      @assignment.grade_student(@student1, grade: 10, grader: @teacher)
      go_to_list_view
      validate_pill('Graded')
      expect(f('.PlannerApp')).not_to include_text('Feedback') # graded != feedback
    end

    it "shows new feedback tag for assignments that has feedback", priority: "1", test_id: 3263154 do
      @assignment.update_submission(@student1, {comment: 'Good', author: @teacher})
      go_to_list_view
      validate_pill('Feedback')
    end

    it "ensures time zone changes update the planner items", priority: "1", test_id: 3306207 do
      go_to_list_view
      time = calendar_time_string(@assignment.due_at).chop
      expect(fxpath("//div[contains(@class, 'PlannerApp')]//span[contains(text(),'Due: #{time}')]")).
        to be_displayed
      @student1.time_zone = 'Asia/Tokyo'
      @student1.save!
      refresh_page

      # the users time zone is not converted to UTC and to balance it we subtract 6 hours from the due time
      time = calendar_time_string(@assignment.due_at+9.hours).chop
      expect(fxpath("//div[contains(@class, 'PlannerApp')]//span[contains(text(),'Due: #{time}')]")).
        to be_displayed
    end

    it "shows missing tag for an assignment with missing submissions.", priority: "1", test_id: 3263153 do
      @assignment.due_at = Time.zone.now - 2.days
      @assignment.save!
      go_to_list_view
      force_click("button:contains('Load prior')")
      planner = f('.PlannerApp')
      expect(planner).to be_displayed
      assn_element = fxpath("//span[contains(text(),'Unnamed Course Assignment')]", planner)
      expect(assn_element).to be_displayed
      validate_pill('Missing')
    end

    it "can follow course link to course", priority: "1", test_id: 3306198 do
      go_to_list_view
      element = flnpt(@course[:name].upcase, f('.PlannerApp'))
      expect_new_page_load do
        element.click
      end
      expect(driver).not_to contain_css('.StudentPlanner__Container')
    end
  end

  context "Graded discussion" do
    before :once do
      @assignment_d = @course.assignments.create!(name: 'assignment',
                                               due_at: Time.zone.now.advance(days:2))
      @discussion = @course.discussion_topics.create!(title: 'Discussion 1',
                                                     message: 'Graded discussion',
                                                     assignment: @assignment_d)
    end

    it "shows and navigates to graded discussions page from student planner", priority: "1", test_id: 3259301 do
      go_to_list_view
      validate_object_displayed('Discussion')
      validate_link_to_url(@discussion, 'discussion_topics')
    end

    it "navigates to the submissions page once the graded discussion has a reply" do
      skip('skip until ADMIN-179')
      go_to_list_view
      @discussion.reply_from(user: @student1, text: 'user reply')
      # for discussion, submissions page has the users id. So, sending the student object instead of submission for id
      validate_link_to_submissions(@assignment_d, @student1, 'assignments')
    end

    it "shows new replies tag for discussion with new replies", priority: "1", test_id: 3284231 do
      @discussion.reply_from(user: @teacher, text: 'teacher reply')
      go_to_list_view
      validate_pill('Replies')
    end

    it "shows the new activity button", priority: "1", test_id: 3263164 do
      # create discussions in the future and in the past to be able to see the new activity button
      past_discussion = graded_discussion_in_the_past
      graded_discussion_in_the_future
      go_to_list_view
      # confirm the past discussion is not loaded
      expect(f('.PlannerApp')).not_to contain_link(past_discussion.title.to_s)
      expect(new_activity_button).to be_displayed
      new_activity_button.click
      expect(f('.PlannerApp')).to contain_link_partial_text(past_discussion.title.to_s)
    end
  end

  context "ungraded discussion" do
    before :once do
      @ungraded_discussion = @course.discussion_topics.create!(user: @teacher, title: 'somebody topic title',
                                                               message: 'somebody topic message',
                                                               todo_date: Time.zone.now + 2.days)
    end

    it "shows and navigates to ungraded discussions with todo dates from student planner", priority:"1", test_id: 3259305 do
      go_to_list_view
      validate_object_displayed('Discussion')
      validate_link_to_url(@ungraded_discussion, 'discussion_topics')
    end

    it 'shows the date in the index page' do
      get "/courses/#{@course.id}/discussion_topics/"
      todo_date = discussion_index_page_detail.text.split("To do ")[1]
      expect(todo_date).to eq(format_time_for_view(@ungraded_discussion.todo_date))
    end

    it 'shows the date in the show page' do
      get "/courses/#{@course.id}/discussion_topics/#{@ungraded_discussion.id}/"
      todo_date = discussion_show_page_detail.text.split("To-Do Date: ")[1]
      expect(todo_date).to eq(format_time_for_view(@ungraded_discussion.todo_date))
    end
  end

  context "wiki_pages" do
    before :once do
      @wiki_page = @course.wiki_pages.create!(title: 'Page1', todo_date: Time.zone.now + 2.days)
    end

    it 'shows the date in the index page' do
      get "/courses/#{@course.id}/pages/"
      wait_for_ajaximations
      expect(f('a[data-sort-field="todo_date"]')).to be_displayed
      expect(f('tbody.collectionViewItems')).to include_text(format_time_for_view(@wiki_page.todo_date))
    end

    it 'shows the date in the show page' do
      get "/courses/#{@course.id}/pages/#{@wiki_page.id}/"
      expect(f('.show-content')).to include_text(format_time_for_view(@wiki_page.todo_date))
    end
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

  context "Peer Reviews" do
    before :once do
      @reviewee = User.create!(name: 'Student 2')
      @course.enroll_student(@reviewee).accept!
      @assignment = @course.assignments.create({
                                                 name: 'Peer Review Assignment',
                                                 due_at: 1.day.from_now,
                                                 submission_types: 'online_text_entry'
                                               })
      submission = @assignment.submit_homework(@reviewee, body: "review this")
      @peer_review = AssessmentRequest.create!({
                                                user: @reviewee,
                                                asset: submission,
                                                assessor_asset: @student1,
                                                assessor: @student1
                                              })
    end

    it "shows and navigates to peer review submissions from the student planner" do
      skip("unskip with ADMIN-1306")
    end
  end

  context "Create To Do Sidebar" do
    before :each do
      user_session(@student1)
    end

    it "opens the sidebar to creata a new To-Do item.", priority: "1", test_id: 3263157 do
      go_to_list_view
      todo_modal_button.click
      expect(todo_save_button).to be_displayed
    end

    it "closes the sidebar tray with the 'X' button.", priority: "1", test_id: 3263163 do
      go_to_list_view
      todo_modal_button.click
      expect(todo_sidebar_modal).to contain_jqcss("button:contains('Save')")
      fj("button:contains('Close')").click
      expect(f('body')).not_to contain_css("[aria-label = 'Add To Do']")
    end

    it "adds text to the details field.", priority: "1", test_id: 3263161 do
      go_to_list_view
      todo_modal_button.click
      todo_details.send_keys("https://imgs.xkcd.com/comics/code_quality_3.png\n")
      expect(todo_details[:value]).to include("https://imgs.xkcd.com/comics/code_quality_3.png")
    end

    it "adds text to the title field.", priority: "1", test_id: 3263158 do
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = f('input', modal)
      element.send_keys("Title Text")
      expect(element[:value]).to include("Title Text")
    end

    it "adds a new date with the date picker.", priority: "1", test_id: 3263159 do
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
      element = ff('input', modal)[1]
      element.click

      # selects a date (the 17th of next month) and verifies it is showing
      fj("button:contains('Next Month')").click
      fj("button:contains('17')").click
      expect(element[:value]).to eq("#{test_month} 17, #{test_year}")
      expect(modal).not_to include_text("Invalid date")
    end

    it "saves new ToDos properly.", priority: "1", test_id: 3263162 do
      go_to_list_view
      todo_modal_button.click
      create_new_todo
      refresh_page

      # verifies that the new To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      expect(f('body')).not_to contain_css(todo_sidebar_modal_selector)
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
      element = title_input("Title Text")
      replace_content(element, "New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("New Text")
      expect(todo_item).not_to include_text("Title Text")
      expect(f('body')).not_to contain_css(todo_sidebar_modal_selector)
    end

    it "edits a completed To Do.", priority: "1" do
      # The following student planner is added to avoid the `beginning of to-do history` image
      # which makes the page to scroll and causes flakiness
      @student1.planner_notes.create!(todo_date: 1.day.ago, title: "Past Title")

      @student1.planner_notes.create!(todo_date: 1.day.from_now, title: "Title Text")
      go_to_list_view

      # complete it
      f('label[for*=Checkbox]').click
      expect(f('input[type=checkbox]:checked')).to be_displayed

      # Opens the To Do edit sidebar
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      fj("a:contains('Title Text')", todo_item).click

      # gives the To Do a new name and saves it
      element = title_input("Title Text")
      replace_content(element, "New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item = todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("New Text")

      # and that it is still complete
      expect(f('input[type=checkbox]:checked')).to be_displayed
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
      alert = driver.switch_to.alert
      expect(alert.text).to eq("Are you sure you want to delete this planner item?")
      alert.accept()
      expect(f('body')).not_to contain_css(todo_sidebar_modal_selector)
      refresh_page

      expect(fj("h2:contains('No Due Dates Assigned')")).to be_displayed
    end

    it "groups the to-do item with other course items", priority: "1", test_id: 3482560 do
      @assignment = @course.assignments.create({
                                                 name: 'Assignment 1',
                                                 due_at: Time.zone.now + 1.day,
                                                 submission_types: 'online_text_entry'
                                               })
      @student1.planner_notes.create!(todo_date: Time.zone.now + 1.day, title: "Title Text", course_id: @course.id)
      go_to_list_view
      course_group = f('ol', f('.PlannerApp'))
      group_items = ff('li', course_group)
      expect(group_items.count).to eq(2)
    end

    it "allows date of a to-do item to be edited.", priority: "1", test_id: 3402913 do
      view_todo_item
      element = ff('input', @modal)[1]
      element.click
      date = format_date_for_view(Time.zone.now, :long).split(" ")
      day = if date[1] == '15'
              date[1] = '20'
              date[0] + ' 20, ' + date[2]
            else
              date[1] = '15'
              date[0] + ' 15, ' + date[2]
            end
      fj("button:contains('#{date[1]}')").click
      todo_save_button.click
      @student_to_do.reload
      expect(format_date_for_view(@student_to_do.todo_date, :long)).to eq(day)
    end

    it "adds date and time to a to-do item.", priority: "1", test_id: 3482559 do
      go_to_list_view
      todo_modal_button.click
      modal = todo_sidebar_modal
      element = ff('input', modal)[1]
      element.click
      fj("button:contains('15')").click

      title_element = title_input
      title_element.send_keys('the title')

      time_element = time_input
      time_element.click
      time_input.clear
      time_element.send_keys('9:00 am')
      time_element.send_keys(:tab)

      todo_save_button.click
      # Gergich will complain, but there's no format_time_for_view format that returns what we need
      expect(PlannerNote.last.todo_date.strftime("%l:%M %p")).to eq(" 9:00 AM")
    end

    it "updates the sidebar when clicking on mutiple to-do items", priority: "1", test_id: 3426619 do
      student_to_do2 = @student1.planner_notes.create!(todo_date: Time.zone.now + 5.minutes,
                                                       title: "Student to do 2")
      view_todo_item
      modal = todo_sidebar_modal(@student_to_do.title)
      title_input = f('input', modal)
      course_name_dropdown = fj('span:contains("Course")>span>span>span>input', modal)

      expect(title_input[:value]).to eq(@student_to_do.title)
      expect(course_name_dropdown[:value]).to eq("#{@course.name} - #{@course.short_name}")

      flnpt(student_to_do2.title).click
      expect(title_input[:value]).to eq(student_to_do2.title)
      expect(course_name_dropdown[:value]).to eq("Optional: Add Course")
    end

    it "allows editing the course of a to-do item", priority: "1", test_id: 3418827 do
      view_todo_item
      
      input = driver.execute_script("return $('[aria-label=\"Edit Student to do\"] input[role=combobox]').filter((i,el) => el.value.includes('Unnamed Course'))[0]")
      input.click
      fj("[role='option'] :contains('Optional: Add Course')").click
      todo_save_button.click
      @student_to_do.reload
      expect(@student_to_do.course_id).to be nil
    end

    it "has courses in the course combo box.", priority: "1", test_id: 3263160 do
      go_to_list_view
      todo_modal_button.click
      input = nil
      keep_trying_until do 
        input = driver.execute_script("return $('[aria-label=\"Add To Do\"] input[role=combobox]').filter((i,el) => el.value.includes('Optional: Add Course'))[0]")
      end
      input.click
      expect(fj("[role='option'] :contains('Unnamed Course')")).to be
    end

    it "ensures time zones with offsets higher than UTC update the planner items" do
      planner_note = @student1.planner_notes.create!(todo_date: (Time.zone.now + 1.day).beginning_of_day,
                                                     title: "Title Text")
      go_to_list_view
      # Opens the To Do edit sidebar
      expect(f('.PlannerApp')).to contain_link_partial_text(planner_note.title)
      flnpt(planner_note.title).click
      @modal = todo_sidebar_modal(planner_note.title)
      expect(ff('input', @modal)[1][:value]).to eq format_date_for_view(planner_note.todo_date, :long)
      @student1.time_zone = 'Minsk'
      @student1.save!
      refresh_page
      expect(f('.PlannerApp')).to contain_link_partial_text(planner_note.title)
      flnpt(planner_note.title).click
      @modal = todo_sidebar_modal(planner_note.title)
      expect(ff('input', @modal)[1][:value]).to eq format_date_for_view(planner_note.todo_date, :long)
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

    it "closes the opportunities dropdown.", priority: "1", test_id: 3281711 do
      go_to_list_view
      open_opportunities_dropdown
      close_opportunities_dropdown
      expect(f('body')).not_to contain_jqcss("button[title='Close opportunities popover']")
    end

    it "links opportunity to the correct assignment page.", priority: "1", test_id: 3281712 do
      go_to_list_view
      open_opportunities_dropdown
      parent = f('#opportunities_parent')
      flnpt('assignmentThatHasToBeDoneNow', parent).click
      expect(f('.description.user_content')).to include_text("This will take a long time")
    end

    it "dismisses assignment from opportunity dropdown.", priority: "1", test_id: 3281713 do
      skip('Failing Jenkins')
      go_to_list_view
      open_opportunities_dropdown
      fj('button:contains("Dismiss assignmentThatHasToBeDoneNow")').click
      expect(f('#opportunities_parent')).not_to contain_jqcss('div:contains("assignmentThatHasToBeDoneNow")')
      expect(f('#opportunities_parent')).not_to contain_jqcss('button:contains("Dismiss assignmentThatHasToBeDoneNow")')
    end

    it "shows missing pill in the opportunities dropdown.", priority: "1", test_id: 3281710 do
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
      Array.new(12){|n| n}.each do |i|
        @course.wiki_pages.create!(title: "Page#{i}", todo_date: Time.zone.now + (i-4).days)
        @course.assignments.create!(name: "assignment#{i}",
                                              due_at: Time.zone.now.advance(days:(i-4)))
        @course.discussion_topics.create!(user: @teacher, title: "topic#{i}",
                                                   message: "somebody topic message ##{i}",
                                                   todo_date: Time.zone.now + (i-4).days)
      end
    end

    it "loads future items at the bottom of the page", priority: "1", test_id: 3263149 do
      go_to_list_view
      current_items = items_displayed.count
      driver.execute_script("window.scrollTo(0,  document.documentElement.scrollHeight);")
      fj('button:contains("Load more")').click
      wait_for_spinner
      expect(items_displayed.count).to be > current_items
    end
  end

  context "with new activity button" do
    before :once do
      @old, @older, @oldest = new_activities_in_the_past
      graded_discussion_in_the_future
    end

    before :each do
      user_session(@student1)
    end

    it "scrolls to the next immediate new activity", priority: "1", test_id: 3468774 do
      skip('fragile, need to skip now')
      go_to_list_view
      new_activity_button.click
      wait_for_spinner
      expect(first_item_on_page).to contain_link(@old.title.to_s)
      new_activity_button.click
      expect(first_item_on_page).to contain_link(@older.title.to_s)
      new_activity_button.click
      expect(first_item_on_page).to contain_link(@oldest.title.to_s)
    end

    it "shows new activity if there are activity above the current scroll position", priority: "1", test_id: 3468775 do
      skip("fragile, need to skip now")
      past_discussion = graded_discussion_in_the_past
      graded_discussion_in_the_future
      go_to_list_view
      new_activity_button.click
      expect(f('.PlannerApp')).to contain_link(past_discussion.title.to_s)
      expect(f('.PlannerApp')).not_to contain_css("button:contains('New Activity')")
      scroll_page_to_bottom
      expect(f('.PlannerApp')).to contain_css("button:contains('New Activity')")
    end
  end

  it "completes and collapses an item", priority: "1", test_id: 3263155 do
    skip("often times out in jenkins. Ticket ADMIN-618 exists to fix this.")
    @course.assignments.create!(name: 'assignment 1',
                                due_at: Time.zone.now + 2.days)
    go_to_list_view
    f('label[for*=Checkbox]').click
    wait_for_ajaximations # wait for the resulting api call to complete
    refresh_page
    wait_for_planner_load
    expect(f('.PlannerApp')).to contain_jqcss('span:contains("Show 1 completed item")')
  end

  context "teacher in a course" do
    before :once do
      @teacher1 = User.create!(name: 'teacher')
      @course.enroll_teacher(@teacher1).accept!
    end

    before :each do
      user_session(@teacher1)
    end

    it "shows correct default time in a wiki page" do
      Timecop.freeze(Time.zone.today) do
        @wiki = @course.wiki_pages.create!(title: 'Default Time Wiki Page')
        get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
        f('#student_planner_checkbox').click
        wait_for_ajaximations
        f('input[name="student_todo_at"]').send_keys(format_date_for_view(Time.zone.now).to_s)
        fj('button:contains("Save")').click
        get("/courses/#{@course.id}/pages/#{@wiki.id}/edit")
        expect(get_value('input[name="student_todo_at"]')).to eq "#{format_date_for_view(Time.zone.today)} 11:59pm"
      end
    end

    it "shows correct default time in a ungraded discussion" do
      Timecop.freeze(Time.zone.today) do
        @discussion = @course.discussion_topics.create!(title: "Default Time Discussion", message: "here is a message", user: @teacher)
        get("/courses/#{@course.id}/discussion_topics/#{@discussion.id}/edit")
        f('#allow_todo_date').click
        wait_for_ajaximations
        f('input[name="todo_date"]').send_keys(format_date_for_view(Time.zone.now).to_s)
        expect_new_page_load { submit_form('.form-actions') }
        get("/courses/#{@course.id}/discussion_topics/#{@discussion.id}/edit")
        expect(get_value('input[name="todo_date"]')).to eq "#{format_date_for_view(Time.zone.today)} 11:59pm"
      end
    end
  end
end
