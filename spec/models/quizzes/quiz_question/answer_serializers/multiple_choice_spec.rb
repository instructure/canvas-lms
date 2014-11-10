require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/id_answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::MultipleChoice do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples 'Answer Serializers'

  let :input do
    2405
  end

  let :output do
    {
      question_5: "2405"
    }.with_indifferent_access
  end

  context 'validations' do
    include_examples 'Id Answer Serializers'
  end
end
