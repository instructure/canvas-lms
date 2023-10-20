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
require_relative "pages/calendar_page"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include CalendarPage

  before(:once) do
    course_with_teacher(active_all: true, new_user: true)
    @student1 = User.create!(name: "Student 1")
    @course.enroll_student(@student1).accept!
    @student1.update!(preferences: { selected_calendar_contexts: ["user_#{@student1.id}", "course_#{@course.id}"] })
    @teacher.update!(preferences: { selected_calendar_contexts: ["user_#{@teacher.id}", "course_#{@course.id}"] })
  end

  context "as the student" do
    before do
      # or some stuff we need to click is "below the fold"

      user_session(@student1)
    end

    it "shows the student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      get "/calendar2"
      wait_for_ajax_requests
      note = f("a.fc-event")
      expect(note.attribute("class")).to include("group_user_#{@student1.id}") # the user calendar
      expect(note).to include_text("Student 1")
      expect(note).to include_text("To Do:")
      expect(note).to include_text("Student To Do")
      expect(note).to contain_css("i.icon-note-light")
    end

    it "creates a new student calendar todo" do
      title = "new todo title"
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-week td").click # click the first day of the month
      wait_for_ajax_requests
      f('li[aria-controls="edit_planner_note_form_holder"]').click # the My To Do tab
      replace_content(f("#planner_note_date"), 0.days.from_now.to_date.iso8601)
      replace_content(f("#planner_note_title"), title)
      f("button.save_note").click
      wait_for_ajax_requests
      note = f("a.fc-event")
      expect(note.attribute("class")).to include("group_user_#{@student1.id}") # the user calendar
      expect(note).to include_text("Student 1")
      expect(note).to include_text("To Do:")
      expect(note).to include_text(title)
      expect(note).to contain_css("i.icon-note-light")
    end

    it "deletes a student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      get "/calendar2"
      wait_for_ajax_requests
      f("a.fc-event").click # click the note
      wait_for_animations
      f(".delete_event_link").click # delete button in the popup
      click_delete_confirm_button # delete button in the confirmation dialog
      expect(f(".fc-view-container")).not_to contain_css("a.fc-event")
    end

    it "edits a student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      new_title = "new todo title"
      get "/calendar2"
      wait_for_ajax_requests
      f("a.fc-event").click # click the note
      f("button.edit_event_link").click # the Edit button
      replace_content(f("#planner_note_title"), new_title)
      f("button.save_note").click
      wait_for_ajaximations
      note = f("a.fc-event")
      expect(note).to include_text(new_title)
    end

    it "shows course calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      get "/calendar2"
      wait_for_ajax_requests
      note = f("a.fc-event")
      expect(note.attribute("class")).to include("group_course_#{@course.id}") # the course calendar
      expect(note).to include_text("Unnamed Course")
      expect(note).to include_text("To Do:")
      expect(note).to include_text("Course To Do")
      expect(note).to contain_css("i.icon-note-light")
    end

    it "edits a course calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      new_title = "new course todo title"
      get "/calendar2"
      wait_for_ajax_requests
      f("a.fc-event").click # click the note
      f("button.edit_event_link").click # the Edit button
      replace_content(f("#planner_note_title"), new_title)
      f("button.save_note").click
      wait_for_ajaximations
      note = f("a.fc-event")
      expect(note).to include_text(new_title)
    end

    it "moves a course calendar todo to the student calendar" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      get "/calendar2"
      wait_for_ajax_requests
      f("a.fc-event").click # click the note
      f("button.edit_event_link").click # the Edit button
      click_option("#planner_note_context", @student1.name)
      f("button.save_note").click
      wait_for_ajaximations
      note = f("a.fc-event")
      expect(note.attribute("class")).to include("group_user_#{@student1.id}")
    end

    it "creates an event on the calendar for wiki pages with to-do date" do
      page = @course.wiki_pages.create!(title: "Page1", todo_date: 30.seconds.from_now)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      note = f(".event-details")
      expect(note).to contain_link(page.title.to_s)
      expect(note).to contain_link(@course.name)
      expect(f(".event-details-timestring")).to include_text(format_date_for_view(page.todo_date))
    end

    it "creates a calendar event for non graded discussions with to do date" do
      discussion = @course.discussion_topics.create!(user: @teacher,
                                                     title: "topic 1",
                                                     message: "somebody topic message",
                                                     todo_date: 30.seconds.from_now)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      note = f(".event-details")
      expect(note).to contain_link(discussion.title.to_s)
      expect(note).to contain_link(@course.name)
      expect(f(".event-details-timestring")).to include_text(format_date_for_view(discussion.todo_date))
    end
  end

  context "as the teacher" do
    before do
      # or some stuff we need to click is "below the fold"

      user_session(@teacher)
    end

    it "edits a todo page" do
      page = @course.wiki_pages.create!(title: "Page1", todo_date: Date.today)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      f(".event-details .edit_event_link").click
      expect(f("#edit_todo_item_form_holder .more_options_link").attribute("href")).to include "/courses/#{@course.id}/pages/#{page.url}/edit"
      replace_content f("#edit_todo_item_form_holder #to_do_item_title"), "edit-page-title"
      replace_content f("#edit_todo_item_form_holder #to_do_item_date"), "2018-01-01"
      f('#edit_todo_item_form_holder button[type="submit"]').click
      wait_for_ajax_requests
      expect(page.reload.todo_date).to eq Date.new(2018, 1, 1)
      expect(page.title).to eq "edit-page-title"
    end

    it "deletes a todo page" do
      page = @course.wiki_pages.create!(title: "Page1", todo_date: Date.today)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      f(".event-details .delete_event_link").click
      click_delete_confirm_button
      wait_for_ajax_requests
      expect(page.reload).to be_deleted
    end

    it "edits a todo discussion" do
      discussion = @course.discussion_topics.create!(user: @teacher,
                                                     title: "topic 1",
                                                     message: "somebody topic message",
                                                     todo_date: Date.today)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      f(".event-details .edit_event_link").click
      expect(f("#edit_todo_item_form_holder .more_options_link").attribute("href")).to include "/courses/#{@course.id}/discussion_topics/#{discussion.id}/edit"
      replace_content f("#edit_todo_item_form_holder #to_do_item_title"), "changed title eh"
      replace_content f("#edit_todo_item_form_holder #to_do_item_date"), "2018-01-01"
      f('#edit_todo_item_form_holder button[type="submit"]').click
      wait_for_ajax_requests
      expect(discussion.reload.todo_date).to eq Date.new(2018, 1, 1)
      expect(discussion.title).to eq "changed title eh"
    end

    it "deletes a todo discussion" do
      discussion = @course.discussion_topics.create!(user: @teacher,
                                                     title: "topic 1",
                                                     message: "somebody topic message",
                                                     todo_date: Date.today)
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-content").click
      f(".event-details .delete_event_link").click
      click_delete_confirm_button
      wait_for_ajax_requests
      expect(discussion.reload).to be_deleted
    end
  end

  context "with teacher and student enrollments" do
    before :once do
      @course1 = @course
      @course2 = course_with_student(user: @user, active_all: true).course
    end

    before do
      # or some stuff we need to click is "below the fold"
      @user.update!(preferences: { selected_calendar_contexts: ["user_#{@user.id}", "course_#{@course1.id}", "course_#{@course2.id}"] })
      user_session(@user)
    end

    it "includes todo items from both" do
      @course1.wiki_pages.create!(title: "Page1", todo_date: Time.zone.today, workflow_state: "unpublished")
      @course2.wiki_pages.create!(title: "Page2", todo_date: Time.zone.today, workflow_state: "published")
      get "/calendar2"
      wait_for_ajax_requests
      fj('.fc-title:contains("Page1")').click
      expect(f(".event-details")).to contain_css(".edit_event_link")
      driver.action.send_keys(:escape).perform
      fj('.fc-title:contains("Page2")').click
      expect(f(".event-details")).not_to contain_css(".edit_event_link")
    end

    it "only offers user and student contexts for planner notes" do
      get "/calendar2"
      wait_for_ajax_requests
      f(".fc-week td").click # click the first day of the month
      wait_for_ajax_requests
      f('li[aria-controls="edit_planner_note_form_holder"]').click # the My To Do tab
      context_codes = ff("#planner_note_context option").pluck("value")
      expect(context_codes).to match_array([@user.asset_string, @course2.asset_string])
    end
  end
end
