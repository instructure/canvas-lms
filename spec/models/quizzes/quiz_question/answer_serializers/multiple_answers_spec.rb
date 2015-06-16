require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::MultipleAnswers do

  include_examples 'Answer Serializers'

  let :factory_options do
    {
      answer_parser_compatibility: true
    }
  end

  let :input do
    [ '9761' ]
  end

  let :output do
    {
      "question_5_answer_9761" => "1",
      "question_5_answer_3079" => "0",
      "question_5_answer_5194" => "0",
      "question_5_answer_166" => "0",
      "question_5_answer_4739" => "0",
      "question_5_answer_2196" => "0",
      "question_5_answer_8982" => "0",
      "question_5_answer_9701" => "0",
      "question_5_answer_7381" => "0"
    }.with_indifferent_access
  end

  # for auto specs
  def format(value)
    [ value ]
  end

  context 'validations' do
    include_examples 'Id Answer Serializers'

    it 'should reject unexpected types' do
      [ nil, 'asdf' ].each do |bad_input|
        rc = subject.serialize(bad_input)
        expect(rc.error).not_to be_nil
        expect(rc.error).to match(/of type array/i)
      end
    end
  end
end
