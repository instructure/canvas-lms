# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../pages/k5_dashboard_page"
require_relative "../pages/k5_dashboard_common_page"
require_relative "../pages/k5_schedule_tab_page"
require_relative "../../../helpers/k5_common"
require_relative "../shared_examples/k5_schedule_shared_examples"
require_relative "../../grades/setup/gradebook_setup"

describe "student k5 dashboard schedule" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5ScheduleTabPageObject
  include K5Common
  include GradebookSetup

  before :once do
    student_setup
  end

  before do
    user_session @student
    @now = Time.zone.now
  end

  context "student events and todos" do
    let(:title) { "Student Todo" }

    before :once do
      @student.planner_notes.create!(todo_date: Time.zone.now, title:)
    end

    it "shows student todo in modal when todo title selected" do
      get "/#schedule"

      expect(todo_edit_pencil).to be_displayed

      click_todo_edit_pencil

      expect(todo_editor_modal).to be_displayed
    end

    it "provide close without edit button", :ignore_js_errors do
      get "/#schedule"

      click_todo_edit_pencil
      wait_for_ajaximations
      new_title = "New Title"
      update_todo_title(title, new_title)
      click_close_editor_modal_button

      expect(todo_item).to include_text(title)
    end

    it "updates student todo with modal" do
      get "/#schedule"

      click_todo_edit_pencil
      new_title = "New Student Todo"
      update_todo_title(title, new_title)
      click_todo_save_button
      expect(wait_for_no_such_element { todo_editor_modal }).to be_truthy
      expect(todo_item).to include_text(new_title)
    end
  end

  context "student-created events" do
    it "shows student-created calender event info when selected" do
      title = "Student Event"
      @student.calendar_events.create!(title:, start_at: Time.zone.now)

      get "/#schedule"

      click_todo_item

      expect(calendar_event_modal).to be_displayed

      click_close_calendar_event_modal
      expect(wait_for_no_such_element { calendar_event_modal }).to be_truthy
    end
  end

  context "missing items dropdown" do
    it "finds no missing dropdown if there are no missing items" do
      assignment = create_dated_assignment(@subject_course, "missing assignment", @now)
      assignment.submit_homework(@student, { submission_type: "online_text_entry", body: "Here it is" })

      get "/#schedule"

      expect(items_missing_exists?).to be_falsey
    end

    it "finds the missing dropdown if there are missing items" do
      create_dated_assignment(@subject_course, "missing assignment", 1.day.ago(@now))

      get "/#schedule"

      expect(items_missing_exists?).to be_truthy
    end

    it "does not display points possible if RQD is enabled" do
      skip "VICE-3678 7/23/2023"
      assignment1 = create_dated_assignment(@subject_course, "missing assignment", 1.day.ago(@now))
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # falsy setting
      Account.default.settings[:restrict_quantitative_data] = { value: false, locked: true }
      Account.default.save!

      get "/#schedule"
      expect(fj(".PlannerItem-styles__score:contains('#{assignment1.points_possible.to_i}')")).to be_present

      # now truthy setting
      Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
      Account.default.save!
      @subject_course.restrict_quantitative_data = true
      @subject_course.save!

      get "/#schedule"

      expect(f("body")).not_to contain_jqcss(".PlannerItem-styles__score:contains('#{assignment1.points_possible.to_i}')")
    end

    it "shows the list of missing assignments in dropdown" do
      assignment1 = create_dated_assignment(@subject_course, "missing assignment1", 1.day.ago(@now))
      create_dated_assignment(@subject_course, "missing assignment2", 1.day.ago(@now))

      get "/#schedule"
      wait_for_ajaximations

      click_missing_items
      wait_for_ajaximations

      assignments_list = missing_assignments

      expect(assignments_list.count).to eq(2)
      expect(assignments_list.first.text).to include("missing assignment1")
      expect(assignment_link(missing_assignments[0], @subject_course.id, assignment1.id)).to be_displayed
    end

    it "clicking list twice hides missing assignments" do
      skip "VICE-3678 7/23/2023"
      create_dated_assignment(@subject_course, "missing assignment1", 1.day.ago(@now))

      get "/#schedule"
      wait_for_ajaximations

      click_missing_items

      assignments_list = missing_assignments

      expect(assignments_list.count).to eq(1)

      click_missing_items
      wait_for_ajaximations

      expect(missing_assignments_exist?).to be_falsey
    end
  end

  context "course-scoped schedule tab included student-only items" do
    it "has todo capabilities for specific student course", custom_timeout: 20 do
      title = "Student Course Todo"
      @student.planner_notes.create!(todo_date: Time.zone.now, title:, course_id: @subject_course.id)

      get "/courses/#{@subject_course.id}#schedule"

      scroll_to_element(todo_item)
      click_todo_item

      expect(todo_editor_modal).to be_displayed
    end
  end

  context "schedule shared examples" do
    it_behaves_like "k5 schedule"
  end
end
