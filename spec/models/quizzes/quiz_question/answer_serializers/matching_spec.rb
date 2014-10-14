require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/support/answer_serializers_specs.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::Matching do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  include_examples 'Answer Serializers'

  let :input do
    [
      { answer_id: 7396, match_id: 6061 }.with_indifferent_access,
      { answer_id: 4224, match_id: 3855 }.with_indifferent_access
    ]
  end

  let :output do
    {
      "question_5_answer_7396" => "6061",
      "question_5_answer_4224" => "3855"
    }.with_indifferent_access
  end

  let :factory_options do
    {
      answer_parser_compatibility: true
    }
  end

  context 'validations' do
    it 'should reject a bad pairing set' do
      [ nil, 'asdf' ].each do |bad_input|
        rc = subject.serialize(bad_input)
        expect(rc.error).not_to be_nil
        expect(rc.error).to match(/of type array/i)
      end
    end

    it 'should reject a bad pairing entry' do
      rc = subject.serialize([ 'asdf' ])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/of type hash/i)
    end

    it 'should reject a pairing entry missing a required parameter' do
      rc = subject.serialize([ match_id: 123 ])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/missing parameter "answer_id"/i)

      rc = subject.serialize([ answer_id: 123 ])
      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/missing parameter "match_id"/i)
    end

    it 'should reject a match for an unknown answer' do
      rc = subject.serialize([{
        answer_id: 123,
        match_id: 6061
      }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown answer/i)
    end

    it 'should reject an unknown match' do
      rc = subject.serialize([{
        answer_id: 7396,
        match_id: 123456
      }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/unknown match/i)
    end

    it 'should reject a bad match' do
      rc = subject.serialize([{
        answer_id: 7396,
        match_id: 'adooken'
      }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end

    it 'should reject a bad answer' do
      rc = subject.serialize([{
        answer_id: 'ping',
        match_id: 6061
      }])

      expect(rc.error).not_to be_nil
      expect(rc.error).to match(/must be of type integer/i)
    end
  end
end
