require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::MultipleDropdowns do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples 'Answer Serializers'

  let :input do
    {
      structure1: 4390,
      event2: 599
    }.with_indifferent_access
  end

  let :output do
    {
      "question_5_#{AssessmentQuestion.variable_id 'structure1'}" => "4390",
      "question_5_#{AssessmentQuestion.variable_id 'event2'}" => "599"
    }.with_indifferent_access
  end

  # for auto specs
  def format(value)
    { structure1: value }
  end

  context 'validations' do
    include_examples 'Id Answer Serializers'

    it 'should reject an answer for an unknown blank' do
      rc = subject.serialize({ foobar: 123456 })
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown blank/i)
    end
  end
end
