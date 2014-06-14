require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Calculated do
  let(:question_data) { QuestionHelpers.fixture('calculated_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]).should be_present }.to_not raise_error
  end

  describe '[:graded]' do
    it 'should reflect the number of graded answers' do
      output = subject.run([
        { correct: true }, { correct: 'true' }, { correct: 'undefined' },
        { correct: false }, { correct: 'false' }, {}
      ])

      output[:graded].should == 2
    end
  end
end
