require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Quizzes::QuizRegrader::Regrader do

  before { Timecop.freeze(Time.local(2013)) }
  after { Timecop.return }

  let(:questions) do
    1.upto(4).map do |i|
      stub(:id => i, :question_data => { :id => i, :regrade_option => 'full_credit'})
    end
  end

  let(:submissions) do
    1.upto(4).map {|i| stub(:id => i, :completed? => true) }
  end

  let(:current_quiz_question_regrades) do
    1.upto(4).map { |i| stub(:quiz_question_id => i, :regrade_option => 'full_credit') }
  end

  let(:quiz) { stub(:quiz_questions => questions,
                    :id => 1,
                    :version_number => 1,
                    :current_quiz_question_regrades => current_quiz_question_regrades,
                    :quiz_submissions => submissions) }

  let(:quiz_regrade) { stub(:id => 1, :quiz => quiz) }

  before do
    quiz.stubs(:current_regrade).returns quiz_regrade
    Quizzes::QuizQuestion.stubs(:where).with(quiz_id: quiz.id).returns questions
    Quizzes::QuizSubmission.stubs(:where).with(quiz_id: quiz.id).returns submissions
  end

  let(:quiz_regrader) { Quizzes::QuizRegrader::Regrader.new(quiz: quiz) }

  describe '#initialize' do
    it 'saves the quiz passed' do
      expect(quiz_regrader.quiz).to eq quiz
    end

    it 'takes an optional submissions argument' do
      submissions = []
      expect(Quizzes::QuizRegrader::Regrader.new(quiz: quiz, submissions:submissions).
        submissions).to eq submissions
    end
  end

  describe "#quiz" do
    it "finds the passed version of the quiz if present" do
      quiz_stub = stub
      options = {
        quiz: quiz,
        version_number: 2
      }

      Version.stubs(:where).with(
        versionable_type: Quizzes::Quiz.class_names,
        number: 2,
        versionable_id: quiz.id
      ).once.returns([ stub(:model => quiz_stub) ])

      expect(Quizzes::QuizRegrader::Regrader.new(options).quiz).to eq quiz_stub
    end
  end

  describe "#submissions" do
    it 'should skip submissions that are in progress' do
      questions << stub(:id => 5, :question_data => {:regrade_option => 'no_regrade'})

      uncompleted_submission = stub(:id => 5, :completed? => false)
      submissions << uncompleted_submission

      expect(quiz_regrader.submissions.length).to eq 4
      expect(quiz_regrader.submissions.detect {|s| s.id == 5 }).to be_nil
    end
  end

  describe '#regrade!' do
    it 'creates a QuizRegrader::Submission for each submission and regrades them' do
      questions << stub(:id => 5, :question_data => {:regrade_option => 'no_regrade'})
      questions << stub(:id => 6, :question_data => {} )

      Quizzes::QuizRegradeRun.expects(:perform).with(quiz_regrade)
      Quizzes::QuizRegrader::Submission.any_instance.stubs(:regrade!)

      quiz_regrader.regrade!
    end
  end
end
