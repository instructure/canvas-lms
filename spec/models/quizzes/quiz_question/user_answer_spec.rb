require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::UserAnswer do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

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
      answer.question_id.should == question_id
    end

    it "saves the points possible" do
      answer.points_possible.should == points_possible
    end
  end
end
