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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../pages/k5_dashboard_common_page'
require_relative '../pages/k5_todo_tab_page'
require_relative '../../../helpers/k5_common'

describe "teacher k5 todo dashboard tab" do
  include_context "in-process server selenium tests"
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5TodoTabPageObject
  include K5Common

  before :once do
    teacher_setup
  end

  before :each do
    user_session @homeroom_teacher
  end

  context 'todo tab basics' do
    it 'provides the homeroom dashboard tabs on dashboard' do
      get "/"

      expect(todo_tab).to be_displayed
    end

    it 'saves tab information for refresh' do
      get "/"

      select_todo_tab
      refresh_page
      wait_for_ajaximations

      expect(driver.current_url).to match(/#todo/)
    end
  end

  context 'todo tab actions' do
    before :once do
      course_with_student(course: @subject_course, name: 'Hardworking Student', active_all: true)
    end

    before :each do
      @assignment1_title = "assignment 1"
      @assignment1 = create_and_submit_assignment(@subject_course, "assignment 1", "assignment 1 submission", 100)
    end

    it 'shows a todo item for item needing grading' do
      get "/#todo"

      todo_element = todo_items[0]
      expect(todo_element).to be_displayed
      expect(todo_element.text).to include("Grade #{@assignment1_title}")
      expect(todo_element.text).to include(@subject_course.name.upcase)
    end

    it 'removes item from todo list when x is clicked' do
      get "/#todo"
      todo_element = todo_items[0]

      delete_todo_item(todo_element)

      expect(todo_item_exists?(todo_item_selector)).to be_falsey
    end

    it 'removes item from list if item is graded', custom_timeout: 20 do
      get "/#todo"

      expect(todo_items[0]).to be_displayed
      @assignment1.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)

      refresh_page

      expect(todo_item_exists?(todo_item_selector)).to be_falsey
    end

    it 'shows a todo item again when new submission is made' do
      @assignment1.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)
      @assignment1.submit_homework(@student, { submission_type: "online_text_entry", body: "Here it is" })

      get "/#todo"

      expect(todo_items[0]).to be_displayed
    end

    it 'shows an empty state panda when there is nothing to grade' do
      @assignment1.grade_student(@student, grader: @homeroom_teacher, score: "90", points_deducted: 0)

      get "/#todo"

      expect(empty_todo_panda).to be_displayed
    end
  end
end
