require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::Numerical do

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
    expect(subject.deserialize({})).to eq nil
  end

  context 'validations' do
    it 'should turn garbage into 0.0' do
      [ 'foobar', nil, { foo: 'bar' } ].each do |garbage|
        rc = subject.serialize(garbage)
        expect(rc.error).to be_nil
        expect(rc.answer).to eq({
          question_5: "0.0"
        }.with_indifferent_access)
      end
    end
  end
end
