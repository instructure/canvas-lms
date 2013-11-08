require 'spec_helper'

describe QuizRegradeRun do

  it "validates presence of quiz_regrade_id" do
    QuizRegradeRun.new(quiz_regrade_id: 1).should be_valid
    QuizRegradeRun.new(quiz_regrade_id: nil).should_not be_valid
  end

  describe "#perform" do
    before(:each) do
      @course = Course.create!
      @quiz = Quiz.create!(:context => @course)
      @user = User.create!

      @regrade = QuizRegrade.create(:user_id => @user.id, :quiz_id => @quiz.id, :quiz_version => 1)
    end

    it "creates a new quiz regrade run" do
      QuizRegradeRun.first.should be_nil

      QuizRegradeRun.perform(@regrade) do
        # noop
      end

      run = QuizRegradeRun.first
      run.started_at.should_not be_nil
      run.finished_at.should_not be_nil
    end
  end
end
