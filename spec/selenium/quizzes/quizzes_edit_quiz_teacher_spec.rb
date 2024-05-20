# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../helpers/quizzes_common"
require_relative "../helpers/assignment_overrides"
require_relative "page_objects/quizzes_edit_page"

describe "editing a quiz" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper
  include QuizzesEditPage

  def delete_quiz
    expect_new_page_load do
      f(".al-trigger").click
      f(".delete_quiz_link").click
      accept_alert
    end
    expect(@quiz.reload).to be_deleted
  end

  context "as a teacher" do
    before(:once) do
      course_with_teacher(active_all: true)
      create_quiz_with_due_date
    end

    before do
      user_session(@teacher)
    end

    context "when the quiz is published" do
      it "indicates the quiz is published", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f("#quiz-draft-state").text.strip).to match accessible_variant_of "Published"
      end

      it "hides the |Save and Publish| button", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f("#content")).not_to contain_css(".save_and_publish")
      end

      it "shows the speedgrader link", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f(".icon-speed-grader")).to be_displayed
      end

      it "remains published after saving changes", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        type_in_tiny("#quiz_description", "changed description")
        click_save_settings_button
        expect(f("#quiz-publish-link")).to include_text "Published"
      end

      it "deletes the quiz", priority: "1" do
        skip_if_safari(:alert)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        delete_quiz
      end

      it "saves question changes with the |Save it now| button", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        # add new question without saving changes
        click_questions_tab
        click_new_question_button
        create_file_upload_question
        cancel_quiz_edit

        # verify alert
        alert_box = f(".alert .unpublished_warning")
        expect(alert_box.text)
          .to eq "You have made changes to the questions in this quiz.\nThese " \
                 "changes will not appear for students until you save the quiz."

        # verify button
        save_it_now_button = fj(".btn.btn-primary", ".edit_quizzes_quiz")
        expect(save_it_now_button).to be_displayed

        # verify the alert disappears after clicking the button
        save_it_now_button.click
        expect(f(".alert .unpublished_warning")).not_to be_displayed

        expect { @quiz.quiz_questions.count }.to become(1)
      end

      it "shows the speed grader link" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        f(".al-trigger").click
        expect(f(".speed-grader-link-quiz")).to be_displayed
      end
    end

    context "when the quiz isn't published" do
      before(:once) do
        @quiz.workflow_state = "unavailable"
        @quiz.save!
      end

      it "indicates the quiz is unpublished", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f("#quiz-draft-state").text.strip).to match accessible_variant_of "Not Published"
      end

      it "hides the speedgrader link", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("#content")).not_to contain_css(".icon-speed-grader")
      end

      it "shows the |Save and Publish| button", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f(".save_and_publish")).to be_displayed
      end

      it "deletes the quiz", priority: "1" do
        skip_if_safari(:alert)
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        delete_quiz
      end

      it "publishes the quiz", priority: "1" do
        skip_if_chrome("research")
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        f("#quiz-publish-link.btn-publish").click
        expect(f("#quiz-publish-link")).to include_text "Unpublish"
      end
    end

    it "hides question form when cancelling edit", priority: "1" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      wait_for_tiny f("#quiz_description")
      click_questions_tab
      click_new_question_button
      f(".question_holder .question_form .cancel_link").click
      expect(f(".question_holder")).not_to contain_css(".question_form")
    end

    it "changes the quiz's description", priority: "1" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      test_text = "changed description"
      type_in_tiny "#quiz_description", test_text, clear: true

      click_save_settings_button
      expect { @quiz.reload.description }.to become("<p>#{test_text}</p>")
    end

    it "loads existing due date", priority: "1" do
      wait_for_ajaximations
      compare_assignment_times(@quiz.reload)
    end

    context "when the quiz has a submission" do
      before(:once) do
        quiz_with_submission
      end

      before do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      end

      it "flashes a warning message", priority: "1" do
        message = "Keep in mind, some students have already taken or started taking this quiz"
        expect(f("#flash_message_holder")).to include_text message
      end

      it "deletes the quiz", priority: "1" do
        skip_if_safari(:alert)
        delete_quiz
      end
    end

    context "when the quiz has a question with a custom name" do
      before do
        @custom_name = "the hardest question ever"
        qd = { question_type: "text_only_question", id: 1, question_name: @custom_name }.with_indifferent_access
        @quiz.quiz_questions.create! question_data: qd
        @quiz.save!
        @quiz.reload
      end

      it "displays the custom name correctly" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab
        expect(f(".question_name")).to include_text @custom_name
      end
    end

    it "does allow safe :redirect_to query param" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit?return_to=#{course_assignments_url(@course)}"
      expect(f("#quiz_edit_actions #cancel_button").attribute("href")).to eq(course_assignments_url(@course))
    end

    it "doesn't allow XSS via :redirect_to query param" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit?return_to=javascript%3Aalert(document.cookie)"
      expect(f("#quiz_edit_actions #cancel_button").attribute("href")).to eq(course_quiz_url(@course, @quiz))
    end

    it "doesn't allow XSS via the return_to query param on Save" do
      # NOTE: the _=1 is required because the deparam method does not correctly parse the first query param
      # canvas-lms/packages/deparam/index.js
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit?_=1&return_to=javascript%3Aalert('sadness')"

      test_text = "changed description for XSS test"
      type_in_tiny "#quiz_description", test_text, clear: true

      click_save_settings_button
      expect(alert_present?).to be_falsey
    end

    context "in a paced course" do
      before(:once) do
        @course.enable_course_paces = true
        @course.save!
      end

      it "displays the course pacing notice in place of due dates" do
        @quiz = create_quiz_with_due_date
        item = add_quiz_to_module

        get "/courses/#{@course.id}/quizzes/#{item.content_id}/edit"
        expect(f(quiz_edit_form)).not_to contain_css(due_date_container)
        expect(f(quiz_edit_form)).to contain_css(course_pacing_notice)
      end

      it "does not display the course pacing notice when feature is off in the account" do
        @course.account.disable_feature!(:course_paces)
        @quiz = create_quiz_with_due_date
        item = add_quiz_to_module

        get "/courses/#{@course.id}/quizzes/#{item.content_id}/edit"
        expect(f(quiz_edit_form)).to contain_css(due_date_container)
        expect(f(quiz_edit_form)).not_to contain_css(course_pacing_notice)
      end
    end
  end
end
