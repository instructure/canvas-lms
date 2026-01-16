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
require_relative "pages/ai_experiences_index_page"

describe "ai experiences index" do
  include_context "in-process server selenium tests"

  let(:visit_and_wait) do
    lambda do |course_id|
      AiExperiencesIndexPage.visit_ai_experiences(course_id)
      wait_for_ajaximations
    end
  end

  before :once do
    @teacher = user_with_pseudonym(active_user: true)
    course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    @course.root_account.enable_feature!(:ai_experiences)

    @student = user_with_pseudonym(active_user: true)
    course_with_student(user: @student, course: @course, active_enrollment: true)

    # Create test AI experiences
    @published_experience = @course.ai_experiences.create!(
      title: "Published Experience",
      learning_objective: "Learn about published experiences",
      pedagogical_guidance: "This is a published experience"
    )
    @published_experience.publish!

    @unpublished_experience = @course.ai_experiences.create!(
      title: "Unpublished Experience",
      learning_objective: "Learn about unpublished experiences",
      pedagogical_guidance: "This is an unpublished experience"
    )

    @another_experience = @course.ai_experiences.create!(
      title: "Another Experience",
      learning_objective: "Learn something else",
      pedagogical_guidance: "Another test experience"
    )
  end

  context "as a teacher" do
    before do
      user_session(@teacher)
      visit_and_wait.call(@course.id)
    end

    describe "page structure" do
      it "displays the AI Experiences heading" do
        expect(AiExperiencesIndexPage.page_heading_text).to eq("AI Experiences")
      end

      it "displays the Create new button" do
        expect(AiExperiencesIndexPage.create_new_button_displayed?).to be true
      end

      it "displays all AI experiences in the list" do
        expect(AiExperiencesIndexPage.ai_experience_exists?(@published_experience.title)).to be true
        expect(AiExperiencesIndexPage.ai_experience_exists?(@unpublished_experience.title)).to be true
        expect(AiExperiencesIndexPage.ai_experience_exists?(@another_experience.title)).to be true
      end

      it "displays AI Experience Options menu" do
        expect(AiExperiencesIndexPage.options_menu_displayed?).to be true
      end
    end

    describe "options menu" do
      it "shows Edit, Test Conversation, and Delete options" do
        AiExperiencesIndexPage.click_options_menu(@published_experience.title)
        expect(AiExperiencesIndexPage.edit_menu_item).to be_displayed
        expect(AiExperiencesIndexPage.test_conversation_menu_item).to be_displayed
        expect(AiExperiencesIndexPage.delete_menu_item).to be_displayed
      end
    end

    describe "create functionality" do
      it "navigates to new AI experience page when Create new is clicked" do
        expect_new_page_load { AiExperiencesIndexPage.click_create_new }
        expect(driver.current_url).to include("/ai_experiences/new")
      end
    end

    describe "read functionality" do
      it "navigates to AI experience detail page when title is clicked" do
        expect_new_page_load { AiExperiencesIndexPage.click_ai_experience_title(@published_experience.title) }
        expect(driver.current_url).to include("/ai_experiences/#{@published_experience.id}")
      end
    end

    describe "update functionality" do
      it "navigates to edit page when Edit option is clicked" do
        AiExperiencesIndexPage.click_options_menu(@published_experience.title)
        expect_new_page_load { AiExperiencesIndexPage.click_edit_option }
        expect(driver.current_url).to include("/ai_experiences/#{@published_experience.id}/edit")
      end
    end

    describe "delete functionality" do
      it "removes deleted AI experience from the list and database" do
        AiExperiencesIndexPage.delete_ai_experience(@unpublished_experience.title)
        wait_for_ajaximations
        # Verify the experience is removed from the page
        expect(AiExperiencesIndexPage.ai_experience_exists?(@unpublished_experience.title)).to be false
        # Verify the experience is deleted in the database
        expect(@unpublished_experience.reload.workflow_state).to eq("deleted")
      end
    end

    describe "navigation functionality" do
      it "navigates to test conversation when Test Conversation option is clicked" do
        AiExperiencesIndexPage.click_options_menu(@published_experience.title)
        expect_new_page_load { AiExperiencesIndexPage.click_test_conversation_option }
        expect(driver.current_url).to include("/ai_experiences/#{@published_experience.id}")
      end
    end
  end

  context "as a student" do
    before do
      user_session(@student)
      get AiExperiencesIndexPage.ai_experiences_url(@course.id)
    end

    it "can access the AI Experiences index page but with view-only access" do
      # Students can now view the AI Experiences page (they will only see published experiences)
      expect(AiExperiencesIndexPage.page_heading_text).to eq("AI Experiences")
      # Create button should not be visible for students
      expect(AiExperiencesIndexPage.create_new_button_displayed?).to be false
    end
  end

  context "empty state" do
    before :once do
      @empty_course = course_factory(active_all: true)
      @empty_course.root_account.enable_feature!(:ai_experiences)
      course_with_teacher(user: @teacher, course: @empty_course, active_enrollment: true)
    end

    before do
      user_session(@teacher)
      visit_and_wait.call(@empty_course.id)
    end

    it "displays the page with no AI experiences" do
      expect(AiExperiencesIndexPage.page_heading_text).to eq("AI Experiences")
      expect(AiExperiencesIndexPage.ai_experience_count).to eq(0)
    end

    it "still displays the Create new button when empty" do
      # In empty state, button is in the AIExperiencesEmptyState component without data-testid
      expect(fj("button:contains('Create new')")).to be_displayed
    end
  end

  context "feature flag disabled" do
    before :once do
      @disabled_course = course_factory(active_all: true)
      @disabled_course.root_account.disable_feature!(:ai_experiences)
      course_with_teacher(user: @teacher, course: @disabled_course, active_enrollment: true)
    end

    before do
      user_session(@teacher)
      get AiExperiencesIndexPage.ai_experiences_url(@disabled_course.id)
    end

    it "cannot access AI Experiences page when feature flag is disabled" do
      # Should show error or redirect - verify AI Experiences heading doesn't exist
      expect(AiExperiencesIndexPage.page_heading_text).not_to eq("AI Experiences")
    end
  end
end
