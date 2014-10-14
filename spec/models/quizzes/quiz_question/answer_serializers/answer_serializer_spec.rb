require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  ASes = Quizzes::QuizQuestion::AnswerSerializers

  it 'automatically registers answer serializers' do
    serializer = nil

    qq = { question_type: 'uber_hax_question' }

    expect { ASes.serializer_for qq }.to raise_error

    class Quizzes::QuizQuestion::AnswerSerializers::UberHax < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    end

    begin
      expect { serializer = ASes.serializer_for qq }.to_not raise_error

      expect(serializer.is_a?(ASes::AnswerSerializer)).to be_truthy
    ensure
      Quizzes::QuizQuestion::AnswerSerializers.send(:remove_const, :UberHax)
    end
  end
end
