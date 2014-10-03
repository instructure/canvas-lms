require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::Numerical do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples 'Answer Serializers'

  let :inputs do
    [ 25.3, 25e-6, '0.12', '3' ]
  end

  let :outputs do
    [
      { question_5: "25.3" }.with_indifferent_access,
      { question_5: "0.000025" }.with_indifferent_access,
      { question_5: "0.12" }.with_indifferent_access,
      { question_5: "3.0" }.with_indifferent_access
    ]
  end

  def sanitize(value)
    Quizzes::QuizQuestion::AnswerSerializers::Util.to_decimal value
  end

  it 'should return nil when un-answered' do
    subject.deserialize({}).should == nil
  end

  context 'validations' do
    it 'should turn garbage into 0.0' do
      [ 'foobar', nil, { foo: 'bar' } ].each do |garbage|
        rc = subject.serialize(garbage)
        rc.error.should be_nil
        rc.answer.should == {
          question_5: "0.0"
        }.with_indifferent_access
      end
    end
  end
end
