require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe QuizQuestion::CalculatedQuestion do
  let(:question_data) do
    {:answer_tolerance => 2.0, :answers => [{:id => 1, :answer => 10}]}
  end

  let(:question) do
    QuizQuestion::CalculatedQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      question.question_id.should == question_data[:id]
    end
  end

  describe "#correct_answer_parts with point tolerance" do
    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should calculate if answer is too far below of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "7.5"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_false
    end

    it "should calculate if answer is too far above of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "12.5"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_false
    end

    it "should calculate if answer is below the answer but within tolerance" do
      answer_data = {:"question_#{question_id}" => "9"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_true
    end

    it "should calculate if answer is above the the answer but within tolerance answer tolerance" do
      answer_data = {:"question_#{question_id}" => "11"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_true
    end
  end

  describe "#correct_answer_parts with percentage tolerance" do
    let(:question_data) do
      {:answer_tolerance => "20.0%", :answers => [{:id => 1, :answer => 10}]}
    end

    let(:question_id)     { 1 }
    let(:points_possible) { 100 }

    it "should calculate if answer is too far below of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "7.5"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_false
    end

    it "should calculate if answer is too far above of the answer tolerance" do
      answer_data = {:"question_#{question_id}" => "12.5"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_false
    end

    it "should calculate if answer is below the answer but within tolerance" do
      answer_data = {:"question_#{question_id}" => "9"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_true
    end

    it "should calculate if answer is above the the answer but within tolerance answer tolerance" do
      answer_data = {:"question_#{question_id}" => "11"}
      user_answer = QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)

      question.correct_answer_parts(user_answer).should be_true
    end
  end
end