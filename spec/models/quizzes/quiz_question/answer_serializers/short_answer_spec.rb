require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/textual_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::ShortAnswer do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples 'Answer Serializers'

  let :input do
    'hello world!'
  end

  let :output do
    {
      question_5: 'hello world!'
    }.with_indifferent_access
  end

  it 'should return nil when un-answered' do
    expect(subject.deserialize({})).to eq nil
  end

  it 'should degracefully sanitize its text' do
    expect(subject.serialize('Hello World!').answer).to eq({
      question_5: 'hello world!'
    }.with_indifferent_access)
  end

  context 'validations' do
    include_examples 'Textual Answer Serializers'
  end
end
