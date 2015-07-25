require File.expand_path(File.dirname(__FILE__) + '/../helpers/quiz_questions_common')

describe 'taking a quiz one question at a time' do
  include_examples 'quiz question selenium tests'

  before(:each) do
    create_oqaat_quiz(publish: true)
  end

  context 'with a student' do

    before(:each) do
      user_session(@student)
    end

    context 'when the \'Lock Questions after Answering\' setting is off' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, false)
        take_the_quiz
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

      it 'warns upon submitting unanswered questions', priority: "1", test_id: 209371 do
        submit_unfinished_quiz('You have 3 unanswered questions')
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
        it_should_show_cant_go_back_warning
        accept_cant_go_back_warning
        answers_flow
      end

      it 'prevents cheating', priority: "1", test_id: 209365 do
        accept_cant_go_back_warning

        click_next_button_and_accept_warning

        navigate_away_and_resume_quiz
        accept_cant_go_back_warning
        it_should_be_on_second_question

        navigate_directly_to_first_question
        it_should_be_on_second_question
      end

      it 'warns upon submitting a quiz when not on the last question', priority: "1", test_id: 209366 do
        accept_cant_go_back_warning
        answer_the_question_correctly
        submit_unfinished_quiz('There are still 2 questions you haven\'t seen')
      end

      it 'warns upon moving on without answering a question', priority: "1", test_id: 209367 do
        accept_cant_go_back_warning
        click_next_button_and_accept_warning
      end

      it 'warns upon resuming', priority: "1", test_id: 209368 do
        it_should_show_cant_go_back_warning
        accept_cant_go_back_warning

        expect_new_page_load(true) { fj('a:contains(\'Quizzes\')').click }

        expect_new_page_load { fj('a:contains(\'OQAAT quiz\')').click }

        fj('#not_right_side .take_quiz_button a:contains(\'Resume Quiz\')').click

        it_should_show_cant_go_back_warning
      end
    end
  end

  context 'with a teacher' do

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
    end

    context 'when the \'Lock Questions after Answering\' setting is on' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, true)
        preview_the_quiz
      end

      it 'prevents going back to previous questions', priority: "1", test_id: 209374 do
        check_if_cant_go_back
      end

      it 'saves answers to questions', priority: "1", test_id: 209375 do
        answers_flow
      end
    end
  end
end