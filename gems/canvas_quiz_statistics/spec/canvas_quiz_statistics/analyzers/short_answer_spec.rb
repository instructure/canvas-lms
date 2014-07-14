require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::ShortAnswer do
  let(:question_data) { QuestionHelpers.fixture('short_answer_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]).should be_present }.to_not raise_error
  end

  it_behaves_like '[:correct]'

  describe '[:responses]' do
    it 'should count those who wrote a correct answer' do
      subject.run([{ answer_id: 4684 }])[:responses].should == 1
      subject.run([{ answer_id: 1797 }])[:responses].should == 1
    end

    it 'should count those who wrote an incorrect answer' do
      subject.run([{ text: 'foobar' }])[:responses].should == 1
    end

    it 'should not count those who wrote nothing' do
      subject.run([{}])[:responses].should == 0
      subject.run([{ text: '' }])[:responses].should == 0
    end

    it 'should not get confused by some non-existing answer' do
      subject.run([{ answer_id: 'asdf' }])[:responses].should == 0
      subject.run([{ answer_id: nil }])[:responses].should == 0
      subject.run([{ answer_id: true }])[:responses].should == 0
    end
  end

  describe '[:answers]' do
    it 'generates the "other" answer for incorrect answers' do
      stats = subject.run([{ text: '12345' }])
      answer = stats[:answers].detect do |answer|
        answer[:id] == CanvasQuizStatistics::Analyzers::Base::Constants::UnknownAnswerKey
      end

      answer.should be_present
      answer[:responses].should == 1
    end
  end
end
