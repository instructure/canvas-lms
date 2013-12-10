require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe QuizQuestion::AnswerSerializers::MultipleDropdowns do
  it_should_behave_like 'Answer Serializers'

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
    it_should_behave_like 'Id Answer Serializers'

    it 'should reject an answer for an unknown blank' do
      rc = subject.serialize({ foobar: 123456 })
      rc.error.should_not be_nil
      rc.error.should match(/unknown blank/i)
    end
  end
end
