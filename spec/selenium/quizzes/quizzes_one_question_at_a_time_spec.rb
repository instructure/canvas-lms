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

require_relative '../common'
require_relative '../helpers/quiz_questions_common'

describe 'taking a quiz one question at a time' do
  include_context 'in-process server selenium tests'
  include QuizQuestionsCommon

  before(:once) do
    create_oqaat_quiz(publish: true)
  end

  context 'as a student' do

    before(:each) do
      user_session(@student)
    end

    context 'when the \'Lock Questions after Answering\' setting is off' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, false)
        begin_quiz
      end

      it 'allows going back to previous questions', priority: "1", test_id: 140611 do
        answer_the_question_correctly
        click_next_button

        click_previous_button
        it_should_be_on_first_question
      end

      it 'allows saving answers to each question', priority: "1", test_id: 209369 do
        answers_flow
      end

      it 'displays one question at a time', priority: "1", test_id: 140610 do
        back_and_forth_flow
      end

      it 'has sidebar navigation', priority: "1", test_id: 140610 do
        it_should_have_sidebar_navigation
      end

      it 'warns upon submitting unanswered questions', priority: "1", test_id: 209371 do
        skip_if_safari(:alert)
        submit_unfinished_quiz('You have 2 unanswered questions')
      end
    end

    context 'when the \'Lock Questions after Answering\' setting is on' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, true)
        take_the_quiz
      end

      it 'prevents going back to previous questions', priority: "1", test_id: 140612 do
        it_should_show_cant_go_back_warning
        accept_cant_go_back_warning
        check_if_cant_go_back
      end

      it 'allows saving answers to each question', priority: "1", test_id: 209364 do
        accept_cant_go_back_warning
        answers_flow
      end

      it 'prevents cheating', priority: "1", test_id: 209365 do
        skip_if_safari(:alert)
        accept_cant_go_back_warning

        click_next_button_and_accept_warning

        navigate_directly_to_first_question
        it_should_be_on_second_question
      end

      it 'warns upon submitting a quiz when not on the last question', priority: "1", test_id: 209366 do
        skip_if_safari(:alert)
        accept_cant_go_back_warning
        answer_the_question_correctly
        submit_unfinished_quiz('There is still 1 question you haven\'t seen')
      end

      it 'warns upon moving on without answering a question', priority: "1", test_id: 209367 do
        skip_if_safari(:alert)
        accept_cant_go_back_warning
        click_next_button_and_accept_warning
      end

      it 'warns upon resuming', priority: "1", test_id: 209368 do
        accept_cant_go_back_warning
        navigate_away_and_resume_quiz
        it_should_show_cant_go_back_warning
      end
    end
  end

  context 'as a teacher' do

    before(:each) do
      user_session(@teacher)
    end

    context 'when the \'Lock Questions after Answering\' setting is off' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, false)
        preview_the_quiz
      end

      it 'saves answers to questions', priority: "1", test_id: 209372 do
        answers_flow
      end

      it 'displays one question at a time', priority: "1", test_id: 209373 do
        back_and_forth_flow
      end

      it 'has sidebar navigation', priority: "1", test_id: 209373 do
        it_should_have_sidebar_navigation
      end
    end

    context 'when the \'Lock Questions after Answering\' setting is on' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, true)
        preview_the_quiz
      end

      it 'prevents going back to previous questions', priority: "1", test_id: 209374 do
        it_should_show_cant_go_back_warning
        accept_cant_go_back_warning

        check_if_cant_go_back
      end

      it 'saves answers to questions', priority: "1", test_id: 209375 do
        it_should_show_cant_go_back_warning
        accept_cant_go_back_warning

        answers_flow
      end
    end
  end
end
