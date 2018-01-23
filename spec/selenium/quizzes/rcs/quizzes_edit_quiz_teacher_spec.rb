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
require_relative '../../helpers/quizzes_common'
require_relative '../../helpers/assignment_overrides'

describe 'editing a quiz' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  def delete_quiz
    expect_new_page_load do
      f('.al-trigger').click
      f('.delete_quiz_link').click
      accept_alert
    end
    expect(@quiz.reload).to be_deleted
  end

  context 'as a teacher' do
    before(:once) do
      course_with_teacher(active_all: true)
      enable_all_rcs @course.account
      create_quiz_with_due_date
    end

    before(:each) do
      user_session(@teacher)
      stub_rcs_config
    end

    it "should show the RCS sidebar when focusing back on the question description box" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      click_questions_tab
      fj('a.add_question_link:visible').click

      hover_and_click('.edit_html:first')
      ffj('.ic-RichContentEditor:visible')[1].click # send focus to the answer editor
      f('.edit_html_done').click
      ffj('.ic-RichContentEditor:visible')[0].click # send focus back to the quiz description box
      expect(f('#editor_tabs')).to be_displayed
    end

    context 'when the quiz is published' do
      it 'indicates the quiz is published', priority: "1", test_id: 351924 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Published'
      end

      it 'hides the |Save and Publish| button', priority: "1", test_id: 255478 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f("#content")).not_to contain_css('.save_and_publish')
      end
    end

    context 'when the quiz isn\'t published' do
      before(:once) do
        @quiz.workflow_state = 'unavailable'
        @quiz.save!
      end

      it 'indicates the quiz is unpublished', priority: "1", test_id: 351925 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('#quiz-draft-state').text.strip).to match accessible_variant_of 'Not Published'
      end

      it 'shows the |Save and Publish| button', priority: "1", test_id: 255479 do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        expect(f('.save_and_publish')).to be_displayed
      end
    end

    it 'hides question form when cancelling edit', priority: "1", test_id: 209956 do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      wait_for_tiny f('#quiz_description')
      click_questions_tab
      click_new_question_button
      f('.question_holder .question_form .cancel_link').click
      expect(f('.question_holder')).not_to contain_css('.question_form')
    end

    it 'loads existing due date', priority: "1", test_id: 209961 do
      wait_for_ajaximations
      compare_assignment_times(@quiz.reload)
    end

    context 'when the quiz has a submission' do
      before(:once) do
        quiz_with_submission
      end

      before(:each) do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      end

      it 'flashes a warning message', priority: "1", test_id: 140609 do
        message = 'Keep in mind, some students have already taken or started taking this quiz'
        expect(f('#flash_message_holder')).to include_text message
      end
    end

    context 'when the quiz has a question with a custom name' do
      before(:each) do
        @custom_name = 'the hardest question ever'
        qd = { question_type: "text_only_question", id: 1, question_name: @custom_name}.with_indifferent_access
        @quiz.quiz_questions.create! question_data: qd
        @quiz.save!
        @quiz.reload
      end

      it 'displays the custom name correctly' do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
        click_questions_tab
        expect(f('.question_name')).to include_text @custom_name
      end
    end
  end
end
