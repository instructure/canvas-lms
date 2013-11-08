require 'active_support'
require_relative '../../mocha_rspec_adapter'
require_relative '../../../lib/quiz_regrading'

describe QuizRegrader::AttemptVersion do

  let(:regrade_options) do
    {1 => 'no_regrade', 2 => 'full_credit', 3 => 'current_correct_only' }
  end

  let(:question_regrades) do
    1.upto(3).each_with_object({}) do |i, hash|
      hash[i] = stub(:quiz_question  => stub(:id => i, :question_data => {:id => i}),
                     :question_data  => {:id => i},
                     :regrade_option => regrade_options[i])
    end
  end

  let(:quiz_data) do
    question_regrades.map {|id, q| q.quiz_question.question_data.dup }
  end

  let(:submission_data) do
    1.upto(3).map {|i| {:question_id => i} }
  end

  let(:submission) do
    stub(:score           => 0,
         :quiz_data       => quiz_data,
         :submission_data => submission_data,
         :write_attribute => {})
  end

  let(:version) do
    stub(:model => submission)
  end

  let(:attempt_version) do
    QuizRegrader::AttemptVersion.new(:version        => version,
                                     :question_regrades => question_regrades)
  end

  describe "#initialize" do
    it "saves a reference to the passed version" do
      attempt_version.version.should == version
    end

    it "saves a reference to the passed regrade quiz questions" do
      attempt_version.question_regrades.should == question_regrades
    end
  end

  describe "#regrade!" do

    it "assigns the model and saves the version" do
      submission_data.each do |answer|
        answer_stub = stub
        answer_stub.expects(:regrade!).once.returns(1)
        QuizRegrader::Answer.expects(:new).returns answer_stub
      end

      # submission data isn't called if not included in question_regrades
      submission_data << {:question_id => 4}
      QuizRegrader::Answer.expects(:new).with(submission_data.last, nil).never

      submission.expects(:score=).with(3)
      submission.expects(:score_before_regrade).returns nil
      submission.expects(:score_before_regrade=).with(0)
      submission.expects(:quiz_data=).with(question_regrades.map { |id, q| q.question_data })

      version.expects(:model=)
      version.expects(:save!)

      attempt_version.regrade!
    end
  end
end
