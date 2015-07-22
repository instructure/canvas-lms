require_relative 'helpers/quiz_questions_common'

describe 'One Question at a Time Quizzes' do
  include_examples 'quiz question selenium tests'

  context 'with a teacher' do

    before(:each) do
      create_oqaat_quiz
      user_session(@teacher)
    end

    context 'when taking an OQAAT quiz' do

      it 'saves answers and grades the quiz', priority: "1", test_id: 209372 do
        preview_the_quiz
        answers_flow
      end

      it 'displays one question at a time', priority: "1", test_id: 209373 do
        preview_the_quiz
        back_and_forth_flow
      end
    end

    context 'when taking a sequential OQAAT quiz' do

      before(:each) do
        @quiz.update_attribute(:cant_go_back, true)
      end

      it 'displays one question at a time and prevents going back', priority: "1", test_id: 209374 do
        preview_the_quiz
        check_if_cant_go_back
      end

      it 'saves answers and grades the quiz', priority: "1", test_id: 209375 do
        preview_the_quiz
        answers_flow
      end
    end
  end
end