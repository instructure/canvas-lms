# frozen_string_literal: true

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

require_relative "../../common"
require_relative "post_grades_tray_page"
require_relative "hide_grades_tray_page"

module Gradebook
  module GradeDetailTray
    extend SeleniumDependencies
    extend PostGradesTray
    extend HideGradesTray

    def self.submission_tray_full_content
      f("#SubmissionTray__Content")
    end

    def self.click_close_tray_button
      force_click("button:contains('Close submission tray')")
    end

    def self.avatar
      f("#SubmissionTray__Avatar")
    end

    def self.student_name
      f("#SubmissionTray__StudentName")
    end

    def self.status_radio_button(type)
      fj(".SubmissionTray__RadioInput label:contains('#{type}')")
    end

    def self.status_radio_button_input(type)
      fj("input[value=#{type}]")
    end

    def self.late_by_input
      fj(".NumberInput__Container-LeftIndent :input")
    end

    def self.late_by_hours
      fj("label:contains('Hours late')")
    end

    def self.late_by_days
      fj("label:contains('Days late')")
    end

    def self.late_penalty_text
      f("#late-penalty-value").text
    end

    def self.final_grade_text
      f("#final-grade-value").text
    end

    def self.group_message
      fj("div:contains('Select Student Group')")
    end

    def self.speedgrader_link
      fj("a:contains('SpeedGrader')")
    end

    def self.submit_for_student_button
      f("button[data-testid='submit-for-student-button']")
    end

    def self.proxy_file_drop
      f("#proxyInputFileDrop")
    end

    def self.proxy_submit_button
      f("button[data-testid='proxySubmit']")
    end

    def self.proxy_submitter_name
      f("span[data-testid='proxy_submitter_name']")
    end

    def self.proxy_date_time
      f("span[data-testid='friendly-date-time']")
    end

    def self.next_assignment_button
      f("#assignment-carousel .right-arrow-button-container button")
    end

    def self.previous_assignment_button
      f("#assignment-carousel .left-arrow-button-container button")
    end

    def self.assignment_link(assignment_name)
      fj("a:contains('#{assignment_name}')")
    end

    def self.student_link(student_name)
      fj("#student-carousel a:contains(#{student_name})")
    end

    def self.navigate_to_next_student_selector
      "#student-carousel .right-arrow-button-container button"
    end

    def self.navigate_to_previous_student_selector
      "#student-carousel .left-arrow-button-container button"
    end

    def self.next_student_button
      f(navigate_to_next_student_selector)
    end

    def self.previous_student_button
      f(navigate_to_previous_student_selector)
    end

    def self.all_comments
      f("#SubmissionTray__Comments")
    end

    def self.delete_comment_button(comment)
      fj("button:contains('Delete Comment: #{comment}')")
    end

    def self.comment_author_link
      ff("#SubmissionTray__Comments a")
    end

    def self.new_comment_input
      f("#SubmissionTray__Comments textarea")
    end

    def self.comment(comment_to_find)
      fj("#SubmissionTray__Comments p:contains('#{comment_to_find}')")
    end

    def self.comment_save_button
      fj("button:contains('Submit')")
    end

    def self.grade_input
      f("#grade-detail-tray--grade-input")
    end

    def self.hidden_pill_locator
      "//*[@id='SubmissionTray__Content']//span[text() = 'Hidden']/../../.."
    end

    # methods
    def self.change_status_to(type)
      status_radio_button(type).click
      driver.action.send_keys(:space).perform
    end

    def self.is_radio_button_selected(type)
      status_radio_button_input(type).selected?
    end

    def self.fetch_late_by_value
      late_by_input["value"]
    end

    def self.edit_late_by_input(value)
      late_by_input.click
      set_value(late_by_input, value)
      # shifting focus from input = saving the changes
      driver.action.send_keys(:tab).perform
      wait_for_ajax_requests
    end

    def self.edit_grade(new_grade)
      grade_input.click
      replace_content(grade_input, new_grade, tab_out: true)
      wait_for_ajax_requests
    end

    def self.add_new_comment(new_comment)
      set_value(new_comment_input, new_comment)
      comment_save_button.click
      wait_for_ajax_requests
    end

    def self.delete_comment(comment)
      delete_comment_button(comment).click
      accept_alert
    end
  end

  module AssignmentPostingPolicy
    extend SeleniumDependencies

    def self.full_content
      # TODO: content finder similar to detail tray
      # f('#SubmissionTray__Content')
    end

    def self.post_policy_type_radio_button(policy)
      fj("#AssignmentPostingPolicyTray__RadioInputGroup label:contains('#{policy}')")
    end

    def self.save_button
      fj("#AssignmentPostingPolicyTray__Buttons button:contains('Save')")
    end
  end
end
