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

require_relative "../../../common"

module Gradebook
  module Settings
    extend SeleniumDependencies

    def self.tab(label:)
      # only works if not currently active
      ff('[role="tab"]').find do |el|
        el.text == label
      end
    end

    def self.click_advanced_tab
      tab(label: "Advanced").click
    end

    def self.click_view_options_tab
      tab(label: "View Options").click
    end

    def self.arrange_by_dropdown
      f('[data-testid="arrange_by_dropdown"]')
    end

    def self.default_order
      f("#sort-default-ascending")
    end

    def self.assignment_name_ascend
      f("#sort-name-ascending")
    end

    def self.assignment_name_descend
      f("#sort-name-descending")
    end

    def self.due_date_ascend
      f("#sort-due_date-ascending")
    end

    def self.due_date_descend
      f("#sort-due_date-descending")
    end

    def self.points_ascend
      f("#sort-points-ascending")
    end

    def self.points_descend
      f("#sort-points-descending")
    end

    def self.modules_ascend
      f("#sort-module_position-ascending")
    end

    def self.modules_descend
      f("#sort-module_position-descending")
    end

    def self.notes_checkbox
      fj('label:contains("Notes")')
    end

    def self.unpublished_checkbox
      fj('label:contains("Unpublished Assignments")')
    end

    def self.split_names_checkbox
      fj('label:contains("Split Student Names")')
    end

    def self.ungraded_as_zero_checkbox
      fj('label:contains("View ungraded as 0")')
    end

    def self.ungraded_as_zero_confirm_button
      f('[data-testid="confirm-button"]')
    end

    def self.click_late_policy_tab
      tab(label: "Late Policies").click
    end

    def self.click_post_policy_tab
      tab(label: "Grade Posting Policy").click
    end

    def self.cancel_button
      f("#gradebook-settings-cancel-button")
    end

    def self.update_button
      f("#gradebook-settings-update-button")
    end

    def self.click_cancel_button
      cancel_button.click
    end

    def self.click_update_button
      update_button.click
      wait_for_ajaximations
    end
  end

  module LatePolicies
    extend SeleniumDependencies

    def self.missing_policy_checkbox
      fj('label:contains("Automatically apply grade for missing submissions")')
    end

    def self.missing_policy_percent_input
      f("#missing-submission-grade")
    end

    def self.late_policy_checkbox
      fj('label:contains("Automatically apply deduction to late submissions")')
    end

    def self.late_policy_deduction_input
      f("#late-submission-deduction")
    end

    def self.late_policy_increment_combobox(increment)
      click_INSTUI_Select_option(f("#late-submission-interval"), increment)
    end

    def self.lowest_grade_percent_input
      f("#late-submission-minimum-percent")
    end

    def self.select_late_policy_tab
      late_policy_tab.click
    end

    def self.create_missing_policy(percent_per_assignment)
      unless missing_policy_checkbox.attribute("checked")
        missing_policy_checkbox.click
      end
      set_value(missing_policy_percent_input, percent_per_assignment)
    end

    def self.disable_missing_policy
      if missing_policy_checkbox.attribute("checked")
        missing_policy_checkbox.click
      end
    end

    def self.disable_late_policy
      if late_policy_checkbox.attribute("checked")
        late_policy_checkbox.click
      end
    end

    def self.create_late_policy(percentage, time_increment, lowest_percentage = nil)
      late_policy_checkbox.click
      set_value(late_policy_deduction_input, percentage)
      late_policy_increment_combobox(time_increment)
      if lowest_percentage
        set_value(lowest_grade_percent_input, lowest_percentage)
      end
    end
  end

  module Advanced
    extend SeleniumDependencies

    def self.select_grade_override_checkbox
      fj('label:contains("Allow final grade override")').click
    end
  end

  module PostingPolicies
    extend SeleniumDependencies

    def self.select_automatically
      fj('label:contains("Automatically Post Grades")').click
    end
  end
end
