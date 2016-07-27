require 'spec_helper'

describe Quizzes::QuizRegrade do

  around do |example|
    Timecop.freeze(Time.zone.local(2013), &example)
  end

  def quiz_regrade
    Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1)
  end

  describe "relationships" do

    it "belongs to a quiz" do
      expect(Quizzes::QuizRegrade.new).to respond_to :quiz
    end

    it "belongs to a user" do
      expect(Quizzes::QuizRegrade.new).to respond_to :user
    end

  end

  describe "validations" do
    it "validates presence of quiz_id" do
      expect(Quizzes::QuizRegrade.new(quiz_id: nil)).not_to be_valid
    end

    it "validates presence of user id" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1,user_id: nil)).not_to be_valid
    end

    it "validates presence of quiz_version" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: nil)).
        not_to be_valid
    end

    it "is valid when all required attributes are present" do
      expect(Quizzes::QuizRegrade.new(quiz_id: 1, user_id: 1, quiz_version: 1)).
        to be_valid
    end
  end
end

