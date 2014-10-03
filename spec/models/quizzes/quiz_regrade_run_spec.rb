require 'spec_helper'

describe Quizzes::QuizRegradeRun do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  it "validates presence of quiz_regrade_id" do
    Quizzes::QuizRegradeRun.new(quiz_regrade_id: 1).should be_valid
    Quizzes::QuizRegradeRun.new(quiz_regrade_id: nil).should_not be_valid
  end

  describe "#perform" do
    before(:each) do
      @course = Course.create!
      @quiz = Quizzes::Quiz.create!(:context => @course)
      @user = User.create!

      @regrade = Quizzes::QuizRegrade.create(:user_id => @user.id, :quiz_id => @quiz.id, :quiz_version => 1)
    end

    it "creates a new quiz regrade run" do
      Quizzes::QuizRegradeRun.first.should be_nil

      Quizzes::QuizRegradeRun.perform(@regrade) do
        # noop
      end

      run = Quizzes::QuizRegradeRun.first
      run.started_at.should_not be_nil
      run.finished_at.should_not be_nil
    end
  end
end
