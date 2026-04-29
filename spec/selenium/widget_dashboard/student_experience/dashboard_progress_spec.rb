# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "page_objects/widget_dashboard_page"
require_relative "../../helpers/student_dashboard_common"

describe "student dashboard Progress overview widget", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include WidgetDashboardPage
  include StudentDashboardCommon

  before :once do
    dashboard_student_setup
    dashboard_course_assignment_setup # Add 11 assignments
    dashboard_course_submission_setup
    dashboard_course_grade_setup
    # Course 1: Graded 2, Submitted 1, Remaining 4 -> 43 % complete
    # Course 2: Graded 1, Submitted 1, Remaining 2 -> 50 % complete

    set_widget_dashboard_flag(feature_status: true)
    enable_widget_dashboard_for(@student)
    add_widget_to_dashboard(@student, :progress_overview, 1)
  end

  before do
    user_session(@student)
  end

  context "progress overview widget smoke tests" do
    it "renders the progress widget on the dashboard" do
      go_to_dashboard

      expect(widget_container("progress_overview")).to be_displayed
      expect(widget_container("progress_overview").text).to include(@course1.name)

      progress_widget = widget_container("progress_overview")
      expect(progress_widget.text).to include("Graded assignments")
      expect(progress_widget.text).to include("Remaining")
    end

    it "navigates to the course when clicking the go to course link" do
      go_to_dashboard

      expect(progress_overview_course_link(@course1.id)).to be_displayed
      progress_overview_course_link(@course1.id).click
      expect(driver.current_url).to include("/courses/#{@course1.id}")
    end
  end

  context "progress overview widget progress counts" do
    it "shows the correct completion percentage" do
      go_to_dashboard
      expect(progress_overview_progression_text(@course1.id).text).to match("43% complete (7 total)")
      expect(progress_overview_progression_text(@course2.id).text).to match("50% complete (4 total)")
    end

    it "shows the correct count of progress items" do
      go_to_dashboard

      expect(progress_overview_course_progress_text(@course1.id).text).to match("2 Graded1 Submitted4 Remaining")
      expect(progress_overview_course_progress_text(@course2.id).text).to match("1 Graded1 Submitted2 Remaining")
      expect(progress_overview_progress_bar_graded(@course1.id).text).to match("2")
      expect(progress_overview_progress_bar_graded(@course2.id).text).to match("1")
      expect(progress_overview_progress_bar_submitted(@course1.id).text).to match("1")
      expect(progress_overview_progress_bar_submitted(@course2.id).text).to match("1")
      expect(progress_overview_progress_bar_remaining(@course1.id).text).to match("4")
      expect(progress_overview_progress_bar_remaining(@course2.id).text).to match("2")
    end
  end

  context "progress overview widget pagination" do
    before :once do
      pagination_course_setup # Adds 20 more courses enrolled for @student
    end

    it "shows pagination when enrolled in more than 5 courses" do
      go_to_dashboard

      expect(all_progress_overview_courses.size).to be 5
      expect(widget_pagination_button("Progress overview", "1")).to be_displayed
      expect(widget_pagination_button("Progress overview", "2")).to be_displayed
      expect(widget_pagination_button("Progress overview", "5")).to be_displayed
    end

    it "navigates between pages and keeps widget visible" do
      go_to_dashboard

      expect(widget_pagination_button("Progress overview", "2")).to be_displayed
      widget_pagination_button("Progress overview", "2").click
      wait_for_ajaximations
      expect(all_progress_overview_courses.size).to eq(5)
      expect(widget_pagination_button("Progress overview", "1")).to be_displayed
      expect(widget_pagination_button("Progress overview", "5")).to be_displayed
      widget_pagination_button("Progress overview", "5").click
      expect(all_progress_overview_courses.size).to eq(2)
      widget_pagination_button("Progress overview", "1").click
      expect(all_progress_overview_courses.size).to eq(5)
    end
  end
end
