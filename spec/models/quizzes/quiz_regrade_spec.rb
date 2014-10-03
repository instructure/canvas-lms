require 'spec_helper'

describe Quizzes::QuizRegrade do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  before { Timecop.freeze(Time.local(2013)) }
  after { Timecop.return }

  def quiz_regrade
    Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1)
  end

  describe "relationships" do

    it "belongs to a quiz" do
      Quizzes::QuizRegrade.new.should respond_to :quiz
    end

    it "belongs to a user" do
      Quizzes::QuizRegrade.new.should respond_to :user
    end

  end

  describe "validations" do
    it "validates presence of quiz_id" do
      Quizzes::QuizRegrade.new(quiz_id: nil).should_not be_valid
    end

    it "validates presence of user id" do
      Quizzes::QuizRegrade.new(quiz_id: 1,user_id: nil).should_not be_valid
    end

    it "validates presence of quiz_version" do
      Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: nil).
        should_not be_valid
    end

    it "is valid when all required attributes are present" do
      Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1).
        should be_valid
    end
  end
end

