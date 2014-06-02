require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleAnswers do
  Constants = CanvasQuizStatistics::Analyzers::Base::Constants

  let(:question_data) { QuestionHelpers.fixture('multiple_answers_question') }

  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]).should be_present }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count students who picked any answer' do
      subject.run([{ answer_5514: '1' }])[:responses].should == 1
    end

    it 'should not count those who did not' do
      subject.run([{}])[:responses].should == 0
      subject.run([{ answer_5514: '0' }])[:responses].should == 0
    end

    it 'should not get confused by an imaginary answer' do
      subject.run([{ answer_1234: '1' }])[:responses].should == 0
    end
  end

  it_behaves_like '[:correct]'
  it_behaves_like '[:partially_correct]'

  describe '[:answers][]' do
    it 'generate "none" answer for those who picked no choice at all' do
      stats = subject.run([{}])

      answer = stats[:answers].detect do |answer|
        answer[:id] == Constants::MissingAnswerKey
      end

      answer.should be_present
      answer[:responses].should == 1
    end
  end

  describe '[:answers][]' do
    describe '[:responses]' do
      it 'should count students who picked this answer' do
        stats = subject.run([{ answer_5514: '1' }])
        stats[:answers].detect { |a| a[:id] == '5514' }[:responses].should == 1
      end

      it 'should not count those who did not' do
        stats = subject.run([{ answer_5514: '1', answer_4261: '0' }])
        stats[:answers].detect { |a| a[:id] == '4261' }[:responses].should == 0
      end
    end
  end
end
