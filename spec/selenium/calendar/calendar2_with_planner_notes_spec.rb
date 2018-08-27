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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:once) do
    # or some stuff we need to click is "below the fold"
    make_full_screen

    Account.default.enable_feature!(:student_planner)
    course_with_teacher(active_all: true, new_user: true)
    @student1 = User.create!(name: 'Student 1')
    @course.enroll_student(@student1).accept!
  end

  context "as the student" do
    before :each do
      user_session(@student1)
    end

    it "should show the student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      get '/calendar2'
      wait_for_ajax_requests
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_user_#{@student1.id}") # the user calendar
      expect(note).to include_text('Student 1')
      expect(note).to include_text('To Do:')
      expect(note).to include_text('Student To Do')
      expect(note).to contain_css('i.icon-note-light')
    end
    it "should create a new student calendar todo" do
      title = "new todo title"
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-week td').click # click the first day of the month
      f('li[aria-controls="edit_planner_note_form_holder"]').click # the To Do tab
      replace_content(f('#planner_note_date'), 0.days.from_now.to_date.iso8601)
      replace_content(f('#planner_note_title'), title)
      f('button.save_note').click
      wait_for_ajax_requests
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_user_#{@student1.id}") # the user calendar
      expect(note).to include_text('Student 1')
      expect(note).to include_text('To Do:')
      expect(note).to include_text(title)
      expect(note).to contain_css('i.icon-note-light')
    end
    it "should delete a student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      get '/calendar2'
      wait_for_ajax_requests
      f('a.fc-event').click # click the note
      wait_for_animations
      f('.delete_event_link').click # delete button in the popup
      f('.btn-primary').click       # delete button in the confirmation dialog
      expect(f('.fc-view-container')).not_to contain_css('a.fc-event')
    end
    it "should edit a student calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Student To Do")
      new_title = "new todo title"
      get '/calendar2'
      wait_for_ajax_requests
      f('a.fc-event').click # click the note
      f('button.edit_event_link').click # the Edit button
      replace_content(f('#planner_note_title'), new_title)
      f('button.save_note').click
      wait_for_ajaximations
      note = f('a.fc-event')
      expect(note).to include_text(new_title)
    end
    it "should show course calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      get '/calendar2'
      wait_for_ajax_requests
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_course_#{@course.id}") # the course calendar
      expect(note).to include_text('Unnamed Course')
      expect(note).to include_text('To Do:')
      expect(note).to include_text('Course To Do')
      expect(note).to contain_css('i.icon-note-light')
    end
    it "should edit a course calendar todo" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      new_title = "new course todo title"
      get '/calendar2'
      wait_for_ajax_requests
      f('a.fc-event').click # click the note
      f('button.edit_event_link').click # the Edit button
      replace_content(f('#planner_note_title'), new_title)
      f('button.save_note').click
      wait_for_ajaximations
      note = f('a.fc-event')
      expect(note).to include_text(new_title)
    end
    it "should move a course calendar todo to the student calendar" do
      @student1.planner_notes.create!(todo_date: 0.days.from_now, title: "Course To Do", course_id: @course.id)
      get '/calendar2'
      wait_for_ajax_requests
      f('a.fc-event').click # click the note
      f('button.edit_event_link').click # the Edit button
      click_option('#planner_note_context', @student1.name)
      f('button.save_note').click
      wait_for_ajaximations
      note = f('a.fc-event')
      expect(note.attribute('class')).to include("group_user_#{@student1.id}")
    end

    it "creates an event on the calendar for wiki pages with to-do date" do
      page = @course.wiki_pages.create!(title: 'Page1', todo_date: 30.seconds.from_now)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      note = f('.event-details')
      expect(note).to contain_link(page.title.to_s)
      expect(note).to contain_link(@course.name)
      expect(f('.event-details-timestring')).to include_text(format_date_for_view(page.todo_date))
    end

    it "creates a calendar event for non graded discussions with to do date" do
      discussion = @course.discussion_topics.create!(user: @teacher, title: "topic 1",
                                        message: "somebody topic message",
                                        todo_date: 30.seconds.from_now)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      note = f('.event-details')
      expect(note).to contain_link(discussion.title.to_s)
      expect(note).to contain_link(@course.name)
      expect(f('.event-details-timestring')).to include_text(format_date_for_view(discussion.todo_date))
    end

    context "with student planner disabled" do
      before :each do
        Account.default.disable_feature!(:student_planner)
      end

      it "should not show todo tab" do
        get '/calendar2'
        wait_for_ajax_requests
        f('.fc-week td').click # click the first day of the month
        expect(f('#edit_event_tabs')).to be_displayed
        expect(f('#edit_event_tabs')).not_to contain_css('[aria-controls="edit_planner_note_form_holder"]')
      end
    end
  end

  context "as the teacher" do
    before :each do
      user_session(@teacher)
    end

    it "edits a todo page" do
      page = @course.wiki_pages.create!(title: 'Page1', todo_date: Date.today)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      f('.event-details .edit_event_link').click
      expect(f('#edit_todo_item_form_holder .more_options_link').attribute('href')).to include "/courses/#{@course.id}/pages/#{page.url}/edit"
      replace_content f('#edit_todo_item_form_holder #to_do_item_title'), 'edit-page-title'
      replace_content f('#edit_todo_item_form_holder #to_do_item_date'), '2018-01-01'
      f('#edit_todo_item_form_holder button[type="submit"]').click
      wait_for_ajax_requests
      expect(page.reload.todo_date).to eq Date.new(2018, 1, 1)
      expect(page.title).to eq 'edit-page-title'
    end

    it "deletes a todo page" do
      page = @course.wiki_pages.create!(title: 'Page1', todo_date: Date.today)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      f('.event-details .delete_event_link').click
      expect(f('#delete_event_dialog').text).to include "Are you sure you want to delete this page?"
      f('#delete_event_dialog').find_element(:xpath, '..').find_element(:css, ".btn-primary").click
      wait_for_ajax_requests
      expect(page.reload).to be_deleted
    end

    it "edits a todo discussion" do
      discussion = @course.discussion_topics.create!(user: @teacher, title: "topic 1",
                                        message: "somebody topic message",
                                        todo_date: Date.today)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      f('.event-details .edit_event_link').click
      expect(f('#edit_todo_item_form_holder .more_options_link').attribute('href')).to include "/courses/#{@course.id}/discussion_topics/#{discussion.id}/edit"
      replace_content f('#edit_todo_item_form_holder #to_do_item_title'), 'changed title eh'
      replace_content f('#edit_todo_item_form_holder #to_do_item_date'), '2018-01-01'
      f('#edit_todo_item_form_holder button[type="submit"]').click
      wait_for_ajax_requests
      expect(discussion.reload.todo_date).to eq Date.new(2018, 1, 1)
      expect(discussion.title).to eq 'changed title eh'
    end

    it "deletes a todo discussion" do
      discussion = @course.discussion_topics.create!(user: @teacher, title: "topic 1",
                                        message: "somebody topic message",
                                        todo_date: Date.today)
      get '/calendar2'
      wait_for_ajax_requests
      f('.fc-content').click
      f('.event-details .delete_event_link').click
      expect(f('#delete_event_dialog').text).to include "Are you sure you want to delete this discussion?"
      f('#delete_event_dialog').find_element(:xpath, '..').find_element(:css, ".btn-primary").click
      wait_for_ajax_requests
      expect(discussion.reload).to be_deleted
    end
  end

  context "with teacher and student enrollments" do
    it "includes todo items from both" do
      course1 = @course
      course2 = course_with_student(user: @user, active_all: true).course
      page1 = course1.wiki_pages.create!(title: 'Page1', todo_date: Date.today, workflow_state: 'unpublished')
      page2 = course2.wiki_pages.create!(title: 'Page2', todo_date: Date.today, workflow_state: 'published')
      user_session(@user)
      get '/calendar2'
      wait_for_ajax_requests
      fj('.fc-title:contains("Page1")').click
      expect(f('.event-details')).to contain_css('.edit_event_link')
      fj('.fc-title:contains("Page2")').click
      expect(f('.event-details')).not_to contain_css('.edit_event_link')
    end
  end
end
