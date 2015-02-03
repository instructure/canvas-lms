require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::UserAnswer do

  let(:answer_data) do
    {:question_1 => ["1"]}
  end
  let(:question_id) { 1 }
  let(:points_possible) { 100 }
  let(:answer) do
    Quizzes::QuizQuestion::UserAnswer.new(question_id, points_possible, answer_data)
  end

  describe "#initialize" do
    it "saves question_ids" do
      expect(answer.question_id).to eq question_id
    end

    it "saves the points possible" do
      expect(answer.points_possible).to eq points_possible
    end
  end
end
