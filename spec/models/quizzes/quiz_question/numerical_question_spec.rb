require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::NumericalQuestion do
  let(:question_data) do
    {:answers => [{:id => 1, :weight => 100, :start => 2,  :end => 3}]}
  end

  let(:question) do
    Quizzes::QuizQuestion::NumericalQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      question.question_id.should == question_data[:id]
    end
  end

  describe "#correct_answer_parts" do
    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should not calculate margin of tolerance for answers if answer text is nil" do
      answer_data = {:"question_#{question_id}" => nil}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
      question.correct_answer_parts(user_answer).should be_nil
    end

    it "should not calculate margin of tolerance for answers if answer text is blank" do
      answer_data = {:"question_#{question_id}" => ""}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
      question.correct_answer_parts(user_answer).should be_false
    end

    it "should calculate if answer falls within start/end range" do
      answer_data = {:"question_#{question_id}" => "2.5"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_true
    end


    it "should calculate if answer falls out of start/end range" do
      answer_data = {:"question_#{question_id}" => "4"}
      user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_false
    end
  end
end