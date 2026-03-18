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
require_relative "../helpers/quizzes_common"
require_relative "../helpers/assignment_overrides"

describe "quizzes with draft state" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before do
    course_with_teacher_logged_in
    @course.update(name: "teacher course")
    @course.save!
    @course.reload
    create_quiz_with_due_date
  end

  context "when there is a single due date" do
    it 'doesn\'t display "Multiple Dates"', priority: "1" do
      get "/courses/#{@course.id}/quizzes"
      expect(f(".ig-details .date-due")).not_to include_text "Multiple Dates"
      expect(f(".ig-details .date-available")).not_to include_text "Multiple Dates"
    end
  end

  context "when there are multiple due dates" do
    before { add_due_date_override(@quiz) }

    it "shows a due date summary", priority: "2" do
      # verify page
      get "/courses/#{@course.id}/quizzes"
      expect(f(".ig-details .date-due")).to include_text "Multiple Dates"
      expect(f(".ig-details .date-available")).to include_text "Multiple Dates"

      # verify tooltips
      date_available = f(".ig-details .date-available")
      driver.action.move_to(date_available).perform
      tooltip_id = date_available.find_element(:css, "a").dom_attribute("aria-describedby")
      tooltip = f("[role='tooltip'][id=#{tooltip_id}]")
      expect(tooltip).to include_text "New Section"
      expect(tooltip).to include_text "Everyone else"

      date_due = f(".ig-details .date-due")
      driver.action.move_to(date_due).perform
      tooltip_id = date_due.find_element(:css, "a").dom_attribute("aria-describedby")
      tooltip = f("[role='tooltip'][id=#{tooltip_id}]")
      expect(tooltip).to include_text "New Section"
      expect(tooltip).to include_text "Everyone else"
    end
  end
end
