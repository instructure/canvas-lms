require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleDropdowns do
  Constants = CanvasQuizStatistics::Analyzers::Base::Constants

  let(:question_data) { QuestionHelpers.fixture('multiple_dropdowns_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]) }.to_not raise_error
  end

  describe '[:answer_sets]' do
    describe '[][:answers][:responses]' do
      it 'should count those who filled in a correct answer' do
        stats = subject.run([
          {
            answer_id_for_organ: '3208'
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == '3208' }
        answer[:responses].should == 1
      end

      it 'should stringify ids' do
        stats = subject.run([
          {
            answer_id_for_organ: 3208
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == '3208' }
        answer[:responses].should == 1
      end

      it 'should count those who filled in an unknown answer' do
        stats = subject.run([
          {
            answer_id_for_organ: '1234'
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }
        answer.should be_present
        answer[:responses].should == 1
      end

      it 'should count those who did not fill in any answer' do
        stats = subject.run([
          {
            answer_id_for_organ: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }
        answer.should be_present
        answer[:responses].should == 1
      end

      it 'should not generate the unknown or missing answers unless needed' do
        stats = subject.run([
          { answer_id_for_organ: "3208" }
        ])

        stats[:answer_sets].detect { |as| as[:text] == 'organ' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          unknown_answer.should_not be_present
          missing_answer.should_not be_present
        end

        stats[:answer_sets].detect { |as| as[:text] == 'color' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          unknown_answer.should_not be_present
          missing_answer.should be_present
          missing_answer[:responses].should == 1
        end
      end
    end
  end

  describe '[:correct]' do
    it 'should count all fully correct responses' do
      stats = subject.run([
        { correct: "true" },
        { correct: true }
      ])

      stats[:correct].should == 2
    end
  end

  describe '[:partial]' do
    it 'should count all partially correct responses' do
      stats = subject.run([
        { correct: "true" },
        { correct: "partial" }
      ])

      stats[:partially_correct].should == 1
    end
  end

  describe '[:incorrect]' do
    it 'should count all incorrect responses' do
      stats = subject.run([
        { correct: nil },
        { correct: false }
      ])

      stats[:incorrect].should == 2
    end
  end

  describe '[:responses]' do
    it 'should count all students who have filled any blank' do
      stats = subject.run([
        {
          answer_id_for_organ: '3208'
        }
      ])

      stats[:responses].should == 1
    end

    it 'should not count students who didnt' do
      subject.run([{}])[:responses].should == 0
    end
  end

  describe '[:answered]' do
    it 'should count students who have filled every blank' do
      stats = subject.run([
        {
          answer_id_for_organ: "3208",
          answer_id_for_color: "1381"
        }
      ])

      stats[:answered].should == 1
    end

    it 'should count students who have filled every blank, even if incorrectly' do
      stats = subject.run([
        {
          answer_id_for_organ: '8331',
          answer_id_for_color: '1638'
        }
      ])

      stats[:answered].should == 1
    end

    it 'should not count a student who has left any blank' do
      stats = subject.run([
        {
          answer_for_color: '1381'
        }
      ])

      stats[:answered].should == 0
    end
  end
end
