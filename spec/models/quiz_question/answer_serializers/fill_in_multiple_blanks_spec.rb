require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/textual_answer_serializers_specs.rb')

describe QuizQuestion::AnswerSerializers::FillInMultipleBlanks do
  it_should_behave_like 'Answer Serializers'

  let :input do
    {
      answer1: 'Red',
      answer3: 'Green',
      answer4: 'Blue'
    }.with_indifferent_access
  end

  let :output do
    {
      "question_5_#{AssessmentQuestion.variable_id 'answer1'}" => 'red',
      "question_5_#{AssessmentQuestion.variable_id 'answer3'}" => 'green',
      "question_5_#{AssessmentQuestion.variable_id 'answer4'}" => 'blue'
    }.with_indifferent_access
  end

  Util = QuizQuestion::AnswerSerializers::Util

  # needed for auto specs
  def sanitize(answer_hash)
    answer_hash.each_pair do |variable, answer_text|
      answer_hash[variable] = Util.sanitize_text(answer_text)
    end

    answer_hash
  end

  # needed for auto specs
  def format(answer_text)
    { answer1: answer_text }
  end

  context 'validations' do
    it_should_behave_like 'Textual Answer Serializers'

    it 'should reject unexpected types' do
      [ 'asdf', nil ].each do |bad_input|
        rc = subject.serialize(bad_input)
        rc.error.should_not be_nil
        rc.error.should match /must be of type hash/i
      end
    end

    it 'should reject an answer to an unknown blank' do
      rc = subject.serialize({ foobar: 'yeeeeeeeeee' })
      rc.error.should_not be_nil
      rc.error.should match /unknown blank/i
    end
  end
end
