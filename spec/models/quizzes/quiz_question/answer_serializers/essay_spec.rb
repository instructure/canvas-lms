require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/textual_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::Essay do

  include_examples 'Answer Serializers'

  let :input do
    'Hello World!'
  end

  let :output do
    {
      question_5: 'Hello World!'
    }.with_indifferent_access
  end

  it 'should return nil when un-answered' do
    expect(subject.deserialize({})).to eq nil
  end

  context 'validations' do
    include_examples 'Textual Answer Serializers'
  end
end
