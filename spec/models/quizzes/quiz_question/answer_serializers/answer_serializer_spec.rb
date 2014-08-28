require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')

describe Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer do
  ASes = Quizzes::QuizQuestion::AnswerSerializers

  it 'automatically registers answer serializers' do
    serializer = nil

    qq = { question_type: 'uber_hax_question' }

    expect { ASes.serializer_for qq }.to raise_error

    class Quizzes::QuizQuestion::AnswerSerializers::UberHax < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    end

    begin
      expect { serializer = ASes.serializer_for qq }.to_not raise_error

      serializer.is_a?(ASes::AnswerSerializer).should be_true
    ensure
      Quizzes::QuizQuestion::AnswerSerializers.send(:remove_const, :UberHax)
    end
  end
end
