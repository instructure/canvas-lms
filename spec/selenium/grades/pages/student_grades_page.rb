# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class StudentGradesPage
  class << self
    include SeleniumDependencies

    # Period components
    def period_options_css
      "#grading_period_select_menu > option"
    end

    # Assignment components
    def assignment_titles_css
      ".student_assignment > th > a"
    end

    def visit_as_teacher(course, student)
      get "/courses/#{course.id}/grades/#{student.id}"
    end

    def visit_as_student(course)
      get "/courses/#{course.id}/grades"
    end

    def final_grade
      f("#submission_final-grade .grade")
    end

    def final_points_possible
      f("#submission_final-grade .points_possible")
    end

    def grading_period_dropdown
      f("#grading_period_select_menu")
    end

    def hidden_eye_icon(scope:)
      fxpath("//*[@title='Instructor has not posted this grade']", scope)
    end

    def select_period_by_name(name)
      click_option(grading_period_dropdown, name)
    end

    def click_apply_button
      f("#apply_select_menus").click
    end

    def assignment_titles
      ff(assignment_titles_css).map(&:text)
    end

    def assignment_row(assignment)
      f("#submission_#{assignment.id}")
    end

    def toggle_comment_module
      fj(".toggle_comments_link .icon-discussion:first").click
    end

    def status_pill(assignment_id, status)
      fj("#submission_#{assignment_id} .submission-#{status}-pill:contains('#{status}')")
    end

    def show_details_button
      f("#show_all_details_button")
    end

    def submission_late_penalty_text(assignment_id)
      fj("#score_details_#{assignment_id} td:contains('Late Penalty:') .error").text
    end

    def late_submission_final_score_text(assignment_id)
      f("#submission_#{assignment_id} .assignment_score .grade").text
    end

    def comment_buttons
      ffxpath('//a[@aria-label="Read comments"]').select(&:displayed?)
    end

    def comments(assignment)
      ff("#comments_thread_#{assignment.id} table tbody tr")
    end

    def submission_comments
      ff('[data-testid="submission-comment"]')
    end

    def fetch_assignment_score(assignment)
      if assignment.grading_type == "letter_grade"
        assignment_row(assignment).find_element(css: ".assignment_score .score_value").text
      else
        assignment_row(assignment).find_element(css: ".assignment_score .grade").text[/\d+/]
      end
    end
  end
end
