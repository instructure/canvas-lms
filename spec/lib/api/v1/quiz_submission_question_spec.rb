require_relative '../../../spec_helper'

describe Api::V1::QuizSubmissionQuestion do
  before :all do
    course_with_student(active_all: true)
    @quiz = Quizzes::Quiz.create!(title: "quiz", context: @course)
    @quiz_submission = @quiz.generate_submission(@student)
  end

  def create_question(type, factory_options = {}, quiz=@quiz)
    factory = method(:"#{type}_question_data")

    # can't test for #arity directly since it might be an optional parameter
    data = factory.parameters.include?([ :opt, :options ]) ?
    factory.call(factory_options) :
    factory.call

    data = data.except('id', 'assessment_question_id')

    qq = quiz.quiz_questions.create!({ question_data: data })
    qq.assessment_question.question_data = data
    qq.assessment_question.save!

    qq
  end

  class QuizSubmissionsQuestionHarness
    include Api::V1::QuizSubmissionQuestion
  end

  let(:api) { QuizSubmissionsQuestionHarness.new }

  describe "#quiz_submissions_questions_json" do
    subject { api.quiz_submission_questions_json(quiz_questions, @quiz_submission) }

    let(:quiz_questions) do
      1.upto(3).map do |i|
        create_question "multiple_choice"
      end
    end

    let(:submission_data) do
      {}
    end

    it "returns json" do
      is_expected.to be_a Hash
    end

    let(:submission_data) do
      []
    end

    it "handles submitted submission_data" do
      is_expected.to be_a Hash
    end
  end
end