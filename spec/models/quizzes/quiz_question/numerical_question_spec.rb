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

    describe 'flexible ranges' do
      def self.test_range(range, answer, is_correct)
        desc = "should calculate if %s falls %s (%d,%d)" % [
          answer, is_correct ? 'within' : 'out of', range[0], range[1]
        ]

        it desc do
          answer_data = {:"question_#{question_id}" => "#{answer}"}
          question = Quizzes::QuizQuestion::NumericalQuestion.new({
            answers: [{
              id: 1,
              weight: 100,
              start: range[0],
              end: range[1]
            }]
          })

          user_answer = Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
          question.correct_answer_parts(user_answer).should == is_correct
        end
      end

      test_range [-3, 3], -2.5, true
      test_range [3, -3], -2.5, true
      test_range [-3, 3], -3.5, false
      test_range [3, -3], -3.5, false
      test_range [2.5, 3.5], 2.5, true
      test_range [2.5, 3.5], 2.49, false
      test_range [100, 50], 75, true
      test_range [50, 100], 75, true
    end
  end
end