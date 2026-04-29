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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/enhanced_individual_gradebook_page"

describe "Enhanced Individual Gradebook - Learning Mastery" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) do
    gradebook_data_setup
    @outcome = outcome_model(context: @course, title: "Test Outcome")
    @assignment = @course.assignments.first
    @alignment = @outcome.align(@assignment, @course)

    @course.enable_feature!(:outcome_gradebook)
  end

  before do
    user_session(@teacher)
  end

  context "Outcome Information section" do
    it "displays total results count for selected outcome" do
      create_learning_outcome_result(@student_1, 5, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_2, 0, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_3, 5, { assignment: @assignment, alignment: @alignment, context: @course })

      EnhancedIndividualGradebookPage.visit(@course.id)
      EnhancedIndividualGradebookPage.select_learning_mastery_tab

      EnhancedIndividualGradebookPage.select_student(@student_1.sortable_name)
      EnhancedIndividualGradebookPage.select_outcome(@outcome.title)

      expect(EnhancedIndividualGradebookPage.outcome_information_section).to be_displayed

      total_results_text = EnhancedIndividualGradebookPage.total_results_text
      expect(total_results_text).to include("Total results")
      expect(total_results_text).to include("3")
    end

    it "displays total results when outcome has results from multiple students" do
      @student_4 = student_in_course(course: @course, active_all: true).user
      @student_5 = student_in_course(course: @course, active_all: true).user

      create_learning_outcome_result(@student_1, 4, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_2, 3, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_3, 5, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_4, 2, { assignment: @assignment, alignment: @alignment, context: @course })
      create_learning_outcome_result(@student_5, 5, { assignment: @assignment, alignment: @alignment, context: @course })

      EnhancedIndividualGradebookPage.visit(@course.id)
      EnhancedIndividualGradebookPage.select_learning_mastery_tab

      EnhancedIndividualGradebookPage.select_student(@student_1.sortable_name)
      EnhancedIndividualGradebookPage.select_outcome(@outcome.title)

      total_results_text = EnhancedIndividualGradebookPage.total_results_text
      expect(total_results_text).to include("5")
    end

    it "displays empty total results when outcome has no results" do
      @outcome_no_results = outcome_model(context: @course, title: "Outcome No Results")
      @outcome_no_results.align(@assignment, @course)

      EnhancedIndividualGradebookPage.visit(@course.id)
      EnhancedIndividualGradebookPage.select_learning_mastery_tab

      EnhancedIndividualGradebookPage.select_student(@student_1.sortable_name)
      EnhancedIndividualGradebookPage.select_outcome(@outcome_no_results.title)

      total_results_text = EnhancedIndividualGradebookPage.total_results_text
      expect(total_results_text).to include("Total results")
    end
  end
end
