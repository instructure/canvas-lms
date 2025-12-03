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

require_relative "../common"
require_relative "pages/ai_experiences_create_edit_page"

describe "ai experiences form" do
  include_context "in-process server selenium tests"

  before :once do
    @teacher = user_with_pseudonym(active_user: true)
    course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    @course.root_account.enable_feature!(:ai_experiences)

    @student = user_with_pseudonym(active_user: true)
    course_with_student(user: @student, course: @course, active_enrollment: true)

    @existing_experience = @course.ai_experiences.create!(
      title: "Existing Experience",
      learning_objective: "Existing objective",
      pedagogical_guidance: "Existing guidance"
    )
  end

  context "create new ai experience" do
    context "as a teacher" do
      before do
        user_session(@teacher)
        # Visit index page first so cancel has somewhere to go back to
        get "/courses/#{@course.id}/ai_experiences"
        wait_for_ajaximations
        AiExperiencesFormPage.visit_new_ai_experience(@course.id)
        wait_for_ajaximations
      end

      describe "page structure" do
        it "displays the New AI Experience heading" do
          expect(AiExperiencesFormPage.page_heading_text).to eq("New AI Experience")
        end

        it "displays all form fields" do
          expect(AiExperiencesFormPage.title_input).to be_displayed
          expect(AiExperiencesFormPage.description_textarea).to be_displayed
          expect(AiExperiencesFormPage.facts_textarea).to be_displayed
          expect(AiExperiencesFormPage.learning_objective_textarea).to be_displayed
          expect(AiExperiencesFormPage.pedagogical_guidance_textarea).to be_displayed
        end

        it "displays action buttons" do
          expect(AiExperiencesFormPage.cancel_button).to be_displayed
          expect(AiExperiencesFormPage.save_as_draft_button).to be_displayed
        end
      end

      describe "form submission" do
        it "can save a new AI experience with valid data" do
          AiExperiencesFormPage.fill_form(
            title: "New Test Experience",
            description: "Test description",
            facts: "Test facts",
            learning_objective: "Test learning objective",
            pedagogical_guidance: "Test pedagogical guidance"
          )

          expect_new_page_load { AiExperiencesFormPage.click_save_as_draft }

          # Verify the experience was created in the database
          experience = AiExperience.find_by(title: "New Test Experience")
          expect(experience).not_to be_nil
          expect(experience.description).to eq("Test description")
          expect(experience.learning_objective).to eq("Test learning objective")
          expect(experience.pedagogical_guidance).to eq("Test pedagogical guidance")
        end

        it "can save with only required fields" do
          AiExperiencesFormPage.fill_form(
            title: "Minimal Experience",
            learning_objective: "Minimal objective",
            pedagogical_guidance: "Minimal guidance"
          )

          expect_new_page_load { AiExperiencesFormPage.click_save_as_draft }

          experience = AiExperience.find_by(title: "Minimal Experience")
          expect(experience).not_to be_nil
        end
      end

      describe "validation" do
        it "shows error when title is missing" do
          AiExperiencesFormPage.fill_form(
            title: "",
            learning_objective: "Test objective",
            pedagogical_guidance: "Test guidance"
          )

          AiExperiencesFormPage.click_save_as_draft
          expect(AiExperiencesFormPage.form_has_error?).to be true
        end

        it "shows error when learning objective is missing" do
          AiExperiencesFormPage.fill_form(
            title: "Test Title",
            learning_objective: "",
            pedagogical_guidance: "Test guidance"
          )

          AiExperiencesFormPage.click_save_as_draft
          expect(AiExperiencesFormPage.form_has_error?).to be true
        end

        it "shows error when pedagogical guidance is missing" do
          AiExperiencesFormPage.fill_form(
            title: "Test Title",
            learning_objective: "Test objective",
            pedagogical_guidance: ""
          )

          AiExperiencesFormPage.click_save_as_draft
          expect(AiExperiencesFormPage.form_has_error?).to be true
        end
      end

      describe "cancel functionality" do
        it "returns to index page when cancel is clicked" do
          AiExperiencesFormPage.click_cancel
          wait_for_ajaximations
          expect(driver.current_url).to include("/courses/#{@course.id}/ai_experiences")
        end
      end
    end

    context "as a student" do
      before do
        user_session(@student)
        get AiExperiencesFormPage.new_ai_experience_url(@course.id)
      end

      it "cannot access the create page" do
        expect(AiExperiencesFormPage.page_heading_text).not_to eq("New AI Experience")
      end
    end
  end

  context "edit existing ai experience" do
    context "as a teacher" do
      before do
        user_session(@teacher)
        AiExperiencesFormPage.visit_edit_ai_experience(@course.id, @existing_experience.id)
        wait_for_ajaximations
      end

      describe "page structure" do
        it "displays the Edit AI Experience heading" do
          expect(AiExperiencesFormPage.page_heading_text).to eq("Edit AI Experience")
        end

        it "pre-populates form fields with existing data" do
          expect(AiExperiencesFormPage.title_value).to eq("Existing Experience")
          expect(AiExperiencesFormPage.learning_objective_value).to eq("Existing objective")
          expect(AiExperiencesFormPage.pedagogical_guidance_value).to eq("Existing guidance")
        end
      end

      describe "form update" do
        it "can update an existing AI experience" do
          AiExperiencesFormPage.fill_title("Updated Experience")
          AiExperiencesFormPage.fill_description("Updated description")

          expect_new_page_load { AiExperiencesFormPage.click_save_as_draft }

          @existing_experience.reload
          expect(@existing_experience.title).to eq("Updated Experience")
          expect(@existing_experience.description).to eq("Updated description")
        end
      end

      describe "delete functionality" do
        it "can delete an AI experience" do
          AiExperiencesFormPage.click_delete
          AiExperiencesFormPage.confirm_delete
          wait_for_ajaximations

          expect(@existing_experience.reload.workflow_state).to eq("deleted")
        end

        it "can cancel delete operation" do
          AiExperiencesFormPage.click_delete
          AiExperiencesFormPage.cancel_delete

          # Should still be on edit page
          expect(AiExperiencesFormPage.page_heading_text).to eq("Edit AI Experience")
          expect(@existing_experience.reload.workflow_state).not_to eq("deleted")
        end
      end
    end

    context "as a student" do
      before do
        user_session(@student)
        get AiExperiencesFormPage.edit_ai_experience_url(@course.id, @existing_experience.id)
      end

      it "cannot access the edit page" do
        expect(AiExperiencesFormPage.page_heading_text).not_to eq("Edit AI Experience")
      end
    end
  end
end
