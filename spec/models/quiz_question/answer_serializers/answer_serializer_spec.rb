require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe QuizQuestion::AnswerSerializers::AnswerSerializer do
  ASes = QuizQuestion::AnswerSerializers

  it 'automatically registers answer serializers' do
    serializer = nil

    qq = {}
    qq.stubs(:data).returns { { question_type: 'uber_hax_question' } }

    expect { ASes.serializer_for qq }.to raise_error

    class UberHax < QuizQuestion::AnswerSerializers::AnswerSerializer
    end

    expect { serializer = ASes.serializer_for qq }.to_not raise_error

    serializer.is_a?(ASes::AnswerSerializer).should be_true
  end
end
