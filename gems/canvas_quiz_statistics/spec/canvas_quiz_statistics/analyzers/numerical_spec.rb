require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Numerical do
  let(:question_data) { QuestionHelpers.fixture('numerical_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect {
      subject.run([]).should be_present
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
        no_answer[:id].should == 'none'
        no_answer[:responses].should == 1
      end
    end

    it 'generates the "other" answer for incorrect answers' do
      stats = subject.run([{ text: '12345' }])
      stats[:answers].last.tap do |other_answer|
        other_answer[:id].should == 'other'
        other_answer[:responses].should == 1
      end
    end
  end

  describe '[:answers][]' do
    describe '[:id]' do
      it 'should stringify the answer id' do
        subject.run([])[:answers].detect { |a| a[:id] == '4343' }.should be_present
      end
    end

    describe '[:is_range]' do
      it 'should be true for range answers' do
        stats = subject.run([])
        stats[:answers].each do |answer|
          # we have one range answer with id 6959
          answer[:is_range].should == (answer[:id] == '6959')
        end
      end
    end

    describe '[:text]' do
      it 'should read 12.00 for an exact answer with no margin' do
        subject.run([])[:answers][0][:text].should == '12.00'
      end

      it 'should read [3.00..6.00] for a range answer' do
        subject.run([])[:answers][1][:text].should == '[3.00..6.00]'
      end

      it 'should read 1.50 for an exact answer with margin' do
        subject.run([])[:answers][3][:text].should == '1.50'
      end
    end

    describe '[:responses]' do
      it 'should count the number of students who got it right' do
        stats = subject.run([{answer_id: 4343}])
        answer = stats[:answers].detect { |answer| answer[:id] == '4343' }
        answer[:responses].should == 1
      end
    end
  end
end
