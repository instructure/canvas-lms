require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/textual_answer_serializers_specs.rb')

describe QuizQuestion::AnswerSerializers::ShortAnswer do
  it_should_behave_like 'Answer Serializers'

  let :input do
    'hello world!'
  end

  let :output do
    {
      question_5: 'hello world!'
    }.with_indifferent_access
  end

  it 'should return nil when un-answered' do
    subject.deserialize({}).should == nil
  end

  it 'should degracefully sanitize its text' do
    subject.serialize('Hello World!').answer.should == {
      question_5: 'hello world!'
    }.with_indifferent_access
  end

  context 'validations' do
    it_should_behave_like 'Textual Answer Serializers'
  end
end
