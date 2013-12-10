require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe QuizQuestion::AnswerSerializers::MultipleChoice do
  it_should_behave_like 'Answer Serializers'

  let :input do
    2405
  end

  let :output do
    {
      question_5: "2405"
    }.with_indifferent_access
  end

  context 'validations' do
    it_should_behave_like 'Id Answer Serializers'
  end
end
