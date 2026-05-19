# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class EnhancedIndividualGradebookPage
  class << self
    include SeleniumDependencies

    def visit(course_id)
      get "/courses/#{course_id}/gradebook/change_gradebook_version?version=individual"
    end

    def learning_mastery_tab
      f("#tab-learning-mastery")
    end

    def learning_mastery_tab_panel
      f("#learning-mastery")
    end

    def student_select
      f('[data-testid="learning-mastery-content-selection-student-select"]')
    end

    def outcome_select
      f('[data-testid="learning-mastery-content-selection-outcome-select"]')
    end

    def outcome_information_section
      f('[data-testid="outcome-information-result"]')
    end

    def outcome_information_total_result
      f('[data-testid="outcome-information-total-result"]')
    end

    def select_learning_mastery_tab
      learning_mastery_tab.click
      wait_for_ajaximations
    end

    def select_student(student_name)
      click_option(student_select, student_name)
      wait_for_ajaximations
    end

    def select_outcome(outcome_title)
      click_option(outcome_select, outcome_title)
      wait_for_ajaximations
    end

    def total_results_text
      outcome_information_total_result.text
    end
  end
end
