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

require_relative "../pages/gradebook_page"
require_relative "../../helpers/gradebook_common"
require_relative "page_objects/learning_mastery_gradebook_page"

describe "Improved Learning Mastery Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  context "as a teacher" do
    before(:once) do
      gradebook_data_setup
      @outcome1 = outcome_model(context: @course, title: "outcome1")
      @outcome2 = outcome_model(context: @course, title: "outcome2")

      @align1 = @outcome1.align(@assignment, @course)
      @align2 = @outcome2.align(@assignment, @course)

      @course.enable_feature!(:outcome_gradebook)
      Account.site_admin.enable_feature!(:improved_lmgb)
    end

    before do
      user_session(@teacher)
    end

    after do
      clear_local_storage
    end

    def navigate_to_gradebook
      get "/courses/#{@course.id}/gradebook?view=learning_mastery"
      wait_for_ajaximations
    end

    it "loads the Learning Mastery v2 Gradebook" do
      navigate_to_gradebook
      expect(LearningMasteryGradebookPage.gradebook_menu).to be_displayed
      expect(LearningMasteryGradebookPage.gradebook_menu.text).to include("Learning Mastery Gradebook")
    end

    it "displays students in the gradebook" do
      navigate_to_gradebook
      expect(LearningMasteryGradebookPage.student_cells.size).to eq(@all_students.size)
      expect(LearningMasteryGradebookPage.student_cells[0].text).to include(@student_1.name)
    end

    it "displays outcomes in the gradebook" do
      navigate_to_gradebook
      outcome_headers = LearningMasteryGradebookPage.outcome_headers
      expect(outcome_headers.size).to eq(2)
      expect(outcome_headers[0].text).to include(@outcome1.title)
      expect(outcome_headers[1].text).to include(@outcome2.title)
    end

    it "displays corresponding outcome score svg for students" do
      create_learning_outcome_result(@student_1, 5, { assignment: @assignment, alignment: @align1, context: @course })
      create_learning_outcome_result(@student_2, 0, { assignment: @assignment, alignment: @align1, context: @course })

      navigate_to_gradebook
      mastered_student_outcome_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_1.id, @outcome1.id)
      expect(mastered_student_outcome_cell).to be_displayed
      expect(mastered_student_outcome_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.mastery_icon_id))

      not_mastered_student_outcome_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_2.id, @outcome1.id)
      expect(not_mastered_student_outcome_cell).to be_displayed
      expect(not_mastered_student_outcome_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.not_mastered_icon_id))
    end

    it "displays export CSV button" do
      navigate_to_gradebook
      expect(LearningMasteryGradebookPage.export_csv_button).to be_displayed
    end

    context "when account_level_mastery_scales is enabled" do
      before do
        Account.site_admin.enable_feature!(:account_level_mastery_scales)
      end

      it "displays scores based on mastery scales" do
        create_learning_outcome_result(@student_1, 0, { assignment: @assignment, alignment: @align1, context: @course })
        create_learning_outcome_result(@student_1, 1, { assignment: @assignment, alignment: @align2, context: @course })
        create_learning_outcome_result(@student_2, 2, { assignment: @assignment, alignment: @align1, context: @course })
        create_learning_outcome_result(@student_2, 3, { assignment: @assignment, alignment: @align2, context: @course })
        create_learning_outcome_result(@student_3, 4, { assignment: @assignment, alignment: @align1, context: @course })
        create_learning_outcome_result(@student_3, 5, { assignment: @assignment, alignment: @align2, context: @course })

        navigate_to_gradebook

        not_mastered_score_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_1.id, @outcome1.id)
        expect(not_mastered_score_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.not_mastered_icon_id))

        below_mastery_score_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_1.id, @outcome2.id)
        expect(below_mastery_score_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.below_mastery_icon_id))

        near_mastery_score_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_2.id, @outcome1.id)
        expect(near_mastery_score_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.near_mastery_icon_id))

        exceeds_mastery_score_cell = LearningMasteryGradebookPage.student_outcome_cell(@student_3.id, @outcome1.id)
        expect(exceeds_mastery_score_cell).to contain_css(LearningMasteryGradebookPage.score_icon_selector(LearningMasteryGradebookPage.exceeds_mastery_icon_id))
      end
    end
  end
end
