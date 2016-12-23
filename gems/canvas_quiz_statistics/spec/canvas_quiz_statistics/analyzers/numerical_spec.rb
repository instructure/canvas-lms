require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Numerical do
  let(:question_data) { QuestionHelpers.fixture('numerical_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect {
      expect(subject.run([])).to be_present
    }.to_not raise_error
  end

  it_behaves_like 'essay [:responses]'
  it_behaves_like 'essay [:full_credit]'

  it_behaves_like '[:correct]'
  it_behaves_like '[:incorrect]'

  describe '[:answers]' do
    it 'generates the "none" answer when a student skips the question' do
      stats = subject.run([ { text: '' } ])
      stats[:answers].last.tap do |no_answer|
        expect(no_answer[:id]).to eq('none')
        expect(no_answer[:responses]).to eq(1)
      end
    end

    it 'generates the "other" answer for incorrect answers' do
      stats = subject.run([{ text: '12345' }])
      stats[:answers].last.tap do |other_answer|
        expect(other_answer[:id]).to eq('other')
        expect(other_answer[:responses]).to eq(1)
      end
    end
  end

  describe '[:answers][]' do
    describe '[:id]' do
      it 'should stringify the answer id' do
        expect(subject.run([])[:answers].detect { |a| a[:id] == '4343' }).to be_present
      end
    end

    describe '[:text]' do
      it 'should read 12.00 for an exact answer with no margin' do
        expect(subject.run([])[:answers][0][:text]).to eq('12.00')
      end

      it 'should read [3.00..6.00] for a range answer' do
        expect(subject.run([])[:answers][1][:text]).to eq('[3.00..6.00]')
      end

      it 'should read 1.50 for an exact answer with margin' do
        expect(subject.run([])[:answers][3][:text]).to eq('1.50')
      end
      
      it 'should read "1.1 (with precision: 2)" for a precision answer' do
        expect(subject.run([])[:answers][4][:text]).to eq("1.1 (with precision: 1)")
      end
    end

    describe '[:responses]' do
      it 'should count the number of students who got it right' do
        stats = subject.run([{answer_id: 4343}])
        answer = stats[:answers].detect { |answer| answer[:id] == '4343' }
        expect(answer[:responses]).to eq(1)
      end
    end
  end
end
