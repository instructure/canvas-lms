require 'active_support'
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizRegrader::Submission do

  let(:regrade_options) do
    {1 => 'no_regrade', 2 => 'full_credit', 3 => 'current_correct_only' }
  end

  let(:question_group) do
    stub(:pick_count => 1, :question_points => 25)
  end

  let(:question_regrades) do
    1.upto(3).each_with_object({}) do |i, hash|
      hash[i] = stub(:quiz_question  => stub(:id => i, :question_data => {:id => i}, :quiz_group => question_group),
                     :question_data  => {:id => i},
                     :regrade_option => regrade_options[i])
    end
  end

  let(:quiz_data) do
    question_regrades.map do |id, q|
      q.quiz_question.question_data.dup.merge(question_name: "Question #{id}")
    end
  end

  let(:submission_data) do
    1.upto(3).map {|i| {:question_id => i} }
  end

  let(:submission) do
    stub(:score                 => 0,
         :score_before_regrade  => 1,
         :quiz_data             => quiz_data,
         :score=                => nil,
         :score_before_regrade= => nil,
         :submission_data       => submission_data,
         :write_attribute       => {})
  end

  let(:wrapper) do
    Quizzes::QuizRegrader::Submission.new(:submission        => submission,
                                          :question_regrades => question_regrades)
  end


  describe "#initialize" do
    it "saves a reference to the passed submission" do
      wrapper.submission.should == submission
    end

    it "saves a reference to the passed regrade quiz questions" do
      wrapper.question_regrades.should == question_regrades
    end
  end

  describe "#regrade!" do
    it "wraps each answer in the submisison's submission_data and regrades" do
      submission_data.each do |answer|
        answer_stub = stub
        answer_stub.expects(:regrade!).once.returns(1)
        Quizzes::QuizRegrader::Answer.expects(:new).returns answer_stub
      end

      # submission data isn't called if not included in question_regrades
      submission_data << {:question_id => 4}
      Quizzes::QuizRegrader::Answer.expects(:new).with(submission_data.last, nil).never

      # submission updates and saves correct data
      submission.expects(:save_with_versioning!).once
      submission.expects(:score=).with(3)
      submission.expects(:score_before_regrade).returns nil
      submission.expects(:score_before_regrade=).with(0)
      submission.expects(:quiz_data=)
      submission.expects(:attempts => stub(:last_versions => []))

      wrapper.regrade!
    end
  end

  describe "#rescored_submission" do
    before do
      regraded_quiz_data = question_regrades.map do |key, qr|
        Quizzes::Quiz.decorate_question_for_submission({
          id: key,
          points_possible: question_group.question_points
        }, key)
      end

      submission.expects(:quiz_data=).with(regraded_quiz_data)

      @regrade_submission = Quizzes::QuizRegrader::Submission.new(
        :submission        => submission,
        :question_regrades => question_regrades)

      @regrade_submission.expects(:answers_to_grade).returns []
    end

    it "scores the submission based on the regraded answers" do
      @regrade_submission.rescored_submission
    end

    it "doesn't change question names" do
      @regrade_submission.stubs(submitted_answer_ids: quiz_data.map { |q| q[:id] })

      question_names = @regrade_submission.rescored_submission.quiz_data.map do |q|
        q[:question_name]
      end

      question_names.sort.should == [
        'Question 1',
        'Question 2',
        'Question 3'
      ]
    end
  end
end
