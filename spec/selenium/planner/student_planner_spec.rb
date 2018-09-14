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
require_relative 'pages/student_planner_page'
require_relative '../admin/pages/student_context_tray_page'

describe "student planner" do
  include_context "in-process server selenium tests"
  include PlannerPageObject

  before :once do
    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true, user_name: 'PlannerTeacher', course_name: 'Planner Course')
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
    switch_to_dashcard_view

    expect(dashboard_card_container).to contain_css("[aria-label='#{@course.name}']")
    expect(dashboard_card_header_content).to contain_css("h2[title='#{@course.name}']")
  end

  it "shows and navigates to announcements page from student planner", priority: "1", test_id: 3259302 do
    announcement = @course.announcements.create!(title: 'Hi there!', message: 'Announcement time!')
    go_to_list_view
    validate_object_displayed(@course.name,'Announcement')
    validate_link_to_url(announcement, 'discussion_topics')
  end

  it "shows and navigates to the calendar events page", priority: "1", test_id: 3488530 do
    event = CalendarEvent.new(title: "New event", start_at: 1.minute.from_now)
    event.context = @course
    event.save!
    go_to_list_view
    validate_object_displayed(@course.name,'Calendar Event')
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
    validate_object_displayed(@course.name,'Announcement')
    elem = f("a[href='/courses/#{@course.id}']")
    url = driver.current_url
    # validate the background image url
    expect(elem[:style]).
      to include("#{url}courses/#{@course.id}/files/#{@course_attachment.id}/download?verifier=#{@course_attachment.uuid}")

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
      validate_object_displayed(@course.name,'Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to graded surveys with due dates", priority: "1", test_id: 3282673 do
      @quiz.update(quiz_type: "graded_survey")
      go_to_list_view
      validate_object_displayed(@course.name,'Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to ungraded surveys with due dates", priority: "1", test_id: 3282674 do
      @quiz.update(quiz_type: "survey")
      go_to_list_view
      validate_object_displayed(@course.name,'Quiz')
      validate_link_to_url(@quiz, 'quizzes')
    end

    it "shows and navigates to practice quizzes with due dates", priority: "1", test_id: 3284242 do
      @quiz.update(quiz_type: "practice_quiz")
      go_to_list_view
      validate_object_displayed(@course.name,'Quiz')
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
      assessor_submission = @assignment.find_or_create_submission(@student1)
      @peer_review = AssessmentRequest.create!({
                                                 user: @reviewee,
                                                 asset: submission,
                                                 assessor_asset: assessor_submission,
                                                 assessor: @student1
                                               })
    end

    it "shows and navigates to peer review submissions from the student planner" do
      skip("unskip with ADMIN-1306")
    end
  end

  context "Create To Do Sidebar" do
    include StudentContextTray

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
      todo_item =todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      expect(f('body')).not_to contain_css(todo_sidebar_modal_selector)
    end

    it "edits a To Do", priority: "1", test_id: 3281714 do
      @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Title Text")
      go_to_list_view
      # Opens the To Do edit sidebar
      todo_item =todo_info_holder
      expect(todo_item).to include_text("To Do")
      expect(todo_item).to include_text("Title Text")
      fj("a:contains('Title Text')", todo_item).click

      # gives the To Do a new name and saves it
      element = title_input("Title Text")
      replace_content(element, "New Text")
      todo_save_button.click

      # verifies that the edited To Do is showing up
      todo_item =todo_info_holder
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
      todo_item =todo_info_holder
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
      todo_item =todo_info_holder
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
      course_group = f('ol', planner_app_div)
      group_items = ff('li', course_group)
      expect(group_items.count).to eq(2)
    end

    it "allows date of a to-do item to be edited.", priority: "1", test_id: 3402913 do
      view_todo_item
      element = ff('input', @modal)[1]
      element.click
      date = format_date_for_view(Time.zone.now, :long).split(" ")
      day =
        if date[1] == '15'
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
      todo_tray_select_course_from_dropdown
      todo_save_button.click
      @student_to_do.reload
      expect(@student_to_do.course_id).to be nil
    end

    it "has courses in the course combo box.", priority: "1", test_id: 3263160 do
      go_to_list_view
      todo_modal_button.click
      todo_tray_course_selector.click
      expect(todo_tray_course_suggestions).to include_text @course.name
    end

    it "ensures time zones with offsets higher than UTC update the planner items" do
      planner_note = @student1.planner_notes.create!(todo_date: (Time.zone.now + 1.day).beginning_of_day,
                                                     title: "Title Text")
      go_to_list_view
      # Opens the To Do edit sidebar
      expect(planner_app_div).to contain_link_partial_text(planner_note.title)
      flnpt(planner_note.title).click
      @modal = todo_sidebar_modal(planner_note.title)
      expect(ff('input', @modal)[1][:value]).to eq format_date_for_view(planner_note.todo_date, :long)
      @student1.time_zone = 'Minsk'
      @student1.save!
      refresh_page
      expect(planner_app_div).to contain_link_partial_text(planner_note.title)
      flnpt(planner_note.title).click
      @modal = todo_sidebar_modal(planner_note.title)
      expect(ff('input', @modal)[1][:value]).to eq format_date_for_view(planner_note.todo_date, :long)
    end
  end

  it "shows and navigates to wiki pages with todo dates from student planner", priority: "1", test_id: 3259304 do
    page = @course.wiki_pages.create!(title: 'Page1', todo_date: Time.zone.now + 2.days)
    go_to_list_view
    validate_object_displayed(@course.name,'Page')
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
      expect(f('body')).not_to contain_jqcss(close_opportunities_selector)
    end

    it "links opportunity to the correct assignment page.", priority: "1", test_id: 3281712 do
      go_to_list_view
      open_opportunities_dropdown
      parent = f('#opportunities_parent')
      flnpt('assignmentThatHasToBeDoneNow', parent).click
      expect(f('.description.user_content')).to include_text("This will take a long time")
    end

    it "dismisses assignment from opportunity dropdown.", priority: "1", test_id: 3281713 do
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
      load_more_button.click
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
      skip('fragile, will be fixed in ADMIN-1449')
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
      skip('fragile, will be fixed in ADMIN-1449')
      past_discussion = graded_discussion_in_the_past
      graded_discussion_in_the_future
      go_to_list_view
      new_activity_button.click
      wait_for_spinner
      expect(planner_app_div).to contain_link(past_discussion.title.to_s)
      expect(planner_app_div).not_to contain_css("button:contains('New Activity')")
      scroll_page_to_bottom
      expect(planner_app_div).to contain_css("button:contains('New Activity')")
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
    expect(planner_app_div).to contain_jqcss('span:contains("Show 1 completed item")')
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

  context "interaction with ToDoSidebar" do
    before :each do
      user_session(@student1)
      @todo_item = @student1.planner_notes.create!(todo_date: 2.days.from_now, title: "Some Todo Item")
    end

    it "completes planner item when dismissed from card view sidebar", prirority: "1", test_id: 3659078 do
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
end
