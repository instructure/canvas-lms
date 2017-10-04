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

require_relative '../../common'
class Gradezilla
  class GradeDetailTray
    class << self
      include SeleniumDependencies

      def submission_tray_full_content
        f('#SubmissionTray__Content')
      end

      def avatar
        f("#SubmissionTray__Avatar")
      end

      def student_name
        f("#SubmissionTray__StudentName")
      end

      def status_radio_button(type)
        fj("label[data-reactid*='#{type}']")
      end

      def status_radio_button_input(type)
        fj("input[value=#{type}]")
      end

      def late_by_input_css
        ".SubmissionTray__RadioInput input[id*='NumberInput']"
      end

      def late_by_hours
        fj("label:contains('Hours late')")
      end

      def late_by_days
        fj("label:contains('Days late')")
      end

      def close_tray_X
        fj("button[data-reactid*='closeButton']")
      end

      def late_penalty_text
        f("#late-penalty-value").text
      end

      def final_grade_text
        f("#final-grade-value").text
      end

      def speedgrader_link
        fj("a:contains('SpeedGrader')")
      end

      def assignment_left_arrow_selector
        '#assignment-carousel .left-arrow-button-container button'
      end

      def assignment_right_arrow_selector
        '#assignment-carousel .right-arrow-button-container button'
      end

      def next_assignment_button
        f(assignment_right_arrow_selector)
      end

      def previous_assignment_button
        f(assignment_left_arrow_selector)
      end

      def assignment_link(assignment_name)
        fj("a:contains('#{assignment_name}')")
      end

      def student_link(student_name)
        fj("a:contains(#{student_name})")
      end

      def navigate_to_next_student_selector
        "#student-carousel .right-arrow-button-container button"
      end

      def navigate_to_previous_student_selector
        "#student-carousel .left-arrow-button-container button"
      end

      def next_student_button
        fj(navigate_to_next_student_selector)
      end

      def previous_student_button
        fj(navigate_to_previous_student_selector)
      end

      def grade_input
        "#grade-input"
      end

      def all_comments
        f("#SubmissionTray__Comments")
      end

      def delete_comment_button(comment)
        fj("button:contains('Delete Comment: #{comment}')")
      end

      def comment_author_link
        ff("#SubmissionTray__Comments a")
      end

      def new_comment_input
        f("#SubmissionTray__Comments textarea")
      end

      def comment(comment_to_find)
        fj("#SubmissionTray__Comments p:contains('#{comment_to_find}')")
      end

      def comment_save_button
        fj("button:contains('Submit')")
      end

      # methods
      def change_status_to(type)
        status_radio_button(type).click
        driver.action.send_keys(:space).perform
      end

      def is_radio_button_selected(type)
        status_radio_button_input(type).selected?
      end

      def fetch_late_by_value
        fj(late_by_input_css)['value']
      end

      def edit_late_by_input(value)
        fj(late_by_input_css).click

        new_value = fj(late_by_input_css)
        set_value(new_value, value)
        new_value.send_keys(:return)

        # shifting focus from input = saving the changes
        driver.execute_script('$(".SubmissionTray__RadioInput input[value=\'late\']").focus()')
      end

      def edit_grade_input(new_grade)
        fj(grade_input).click

        edit_grade = fj(grade_input)
        set_value(edit_grade, new_grade)

        edit_grade.send_keys(:return)
      end

      def add_new_comment(new_comment)
        set_value(new_comment_input, new_comment)
        comment_save_button.click
      end

      def delete_comment(comment)
        delete_comment_button(comment).click
        accept_alert
      end

    end
  end
end
