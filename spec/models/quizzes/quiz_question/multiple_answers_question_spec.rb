require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::MultipleAnswersQuestion do

  let(:question_data) do
    {:id => 1}
  end

  let(:question) do
    Quizzes::QuizQuestion::MultipleAnswersQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      expect(question.question_id).to eq question_data[:id]
    end
  end
end
