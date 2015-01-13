require_relative "helpers/quiz_questions_common"

describe "One Question at a Time Quizzes" do

  include_examples "quiz question selenium tests"

  context "as a teacher" do
    before do
      create_oqaat_quiz
      user_session(@teacher)
    end

    context "on a OQAAT quiz" do
      it "saves answers and grades the quiz" do
        preview_the_quiz
        answers_flow
      end

      it "displays one question at a time" do
        preview_the_quiz
        back_and_forth_flow
      end
    end

    context "on a sequential OQAAT quiz" do
      before do
        @quiz.update_attribute(:cant_go_back, true)
      end

      it "displays one question at a time but you cant go back" do
        skip("193")
        preview_the_quiz
        sequential_flow
      end

      it "saves answers and grades the quiz" do
        preview_the_quiz
        answers_flow
      end
    end
  end
end
