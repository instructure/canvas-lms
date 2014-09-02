require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleChoice do
  let(:question_data) { QuestionHelpers.fixture('multiple_choice_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]).should be_present }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count those who picked a correct answer' do
      subject.run([{ answer_id: 3023 }])[:responses].should == 1
    end

    it 'should count those who picked an incorrect answer' do
      subject.run([{ answer_id: 8899 }])[:responses].should == 1
    end

    it 'should not count those who picked nothing' do
      subject.run([{}])[:responses].should == 0
    end

    it 'should not get confused by picking some non-existing answer' do
      subject.run([{ answer_id: 'asdf' }])[:responses].should == 0
      subject.run([{ answer_id: nil }])[:responses].should == 0
      subject.run([{ answer_id: true }])[:responses].should == 0
    end
  end

  describe '[:answers][]' do
    describe '[:id]' do
      it 'should stringify ids' do
        subject.run([])[:answers].map { |a| a[:id] }.sort.should == %w[
          3023
          5646
          7907
          8899
        ]
      end
    end

    describe '[:text]' do
      it 'should be included' do
        subject.run([])[:answers][0][:text].should == 'A'
      end

      context 'when missing' do
        it 'should use a stripped version of :html if present' do
          data = question_data.clone
          data[:answers][0].merge!({
            html: '<p>Hi.</p>',
            text: ''
          })

          subject = described_class.new(data)
          subject.run([])[:answers][0][:text].should == 'Hi.'
        end

        it 'should just accept how things are, otherwise' do
          data = question_data.clone
          data[:answers][0].merge!({ html: '', text: '' })

          subject = described_class.new(data)
          subject.run([])[:answers][0][:text].should == ''
        end
      end
    end

    describe '[:correct]' do
      it 'should be true for those with a weight of 100' do
        subject.run([])[:answers][0][:correct].should == true
        subject.run([])[:answers][1][:correct].should == false
        subject.run([])[:answers][2][:correct].should == false
        subject.run([])[:answers][3][:correct].should == false
      end
    end

    describe '[:responses]' do
      it 'should count the number of students who got it right' do
        stats = subject.run([{ answer_id: 3023 }])
        answer = stats[:answers].detect { |answer| answer[:id] == '3023' }
        answer[:responses].should == 1
      end
    end
  end
end
