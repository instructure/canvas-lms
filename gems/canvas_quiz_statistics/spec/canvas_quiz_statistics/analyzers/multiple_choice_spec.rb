require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleChoice do
  let(:question_data) { QuestionHelpers.fixture('multiple_choice_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count those who picked a correct answer' do
      expect(subject.run([{ answer_id: 3023 }])[:responses]).to eq(1)
    end

    it 'should count those who picked an incorrect answer' do
      expect(subject.run([{ answer_id: 8899 }])[:responses]).to eq(1)
    end

    it 'should not count those who picked nothing' do
      expect(subject.run([{}])[:responses]).to eq(0)
    end

    it 'should not get confused by picking some non-existing answer' do
      expect(subject.run([{ answer_id: 'asdf' }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: nil }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: true }])[:responses]).to eq(0)
    end
  end

  describe '[:answers][]' do
    describe '[:id]' do
      it 'should stringify ids' do
        expect(subject.run([])[:answers].map { |a| a[:id] }.sort).to eq(%w[
          3023
          5646
          7907
          8899
        ])
      end
    end

    describe '[:text]' do
      it 'should be included' do
        expect(subject.run([])[:answers][0][:text]).to eq('A')
      end

      context 'when missing' do
        it 'should use a stripped version of :html if present' do
          data = question_data.clone
          data[:answers][0].merge!({
            html: '<p>Hi.</p>',
            text: ''
          })

          subject = described_class.new(data)
          expect(subject.run([])[:answers][0][:text]).to eq('Hi.')
        end

        it 'should just accept how things are, otherwise' do
          data = question_data.clone
          data[:answers][0].merge!({ html: '', text: '' })

          subject = described_class.new(data)
          expect(subject.run([])[:answers][0][:text]).to eq('')
        end
      end
    end

    describe '[:correct]' do
      it 'should be true for those with a weight of 100' do
        expect(subject.run([])[:answers][0][:correct]).to eq(true)
        expect(subject.run([])[:answers][1][:correct]).to eq(false)
        expect(subject.run([])[:answers][2][:correct]).to eq(false)
        expect(subject.run([])[:answers][3][:correct]).to eq(false)
      end
    end

    describe '[:responses]' do
      it 'should count the number of students who got it right' do
        stats = subject.run([{ answer_id: 3023 }])
        answer = stats[:answers].detect { |answer| answer[:id] == '3023' }
        expect(answer[:responses]).to eq(1)
      end
    end
  end
end
