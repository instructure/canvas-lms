require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::FillInMultipleBlanks do
  FIMB = CanvasQuizStatistics::Analyzers::FillInMultipleBlanks

  let(:question_data) { QuestionHelpers.fixture('fill_in_multiple_blanks_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect {
      subject.run([])
    }.to_not raise_error
  end

  describe '[:answer_sets]' do
    describe '[][:answers][:responses]' do
      it 'should count those who filled in a correct answer' do
        stats = subject.run([
          {
            answer_for_color1: "Red",
            answer_id_for_color1: "9711"
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:text] == 'Red' }
        answer[:responses].should == 1
      end

      it 'should stringify ids' do
        stats = subject.run([
          {
            answer_for_color1: "Red",
            answer_id_for_color1: 9711
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:text] == 'Red' }
        answer[:responses].should == 1
      end

      it 'should count those who filled in an unknown answer' do
        stats = subject.run([
          {
            answer_for_color1: "purple",
            answer_id_for_color1: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:id] == FIMB::UnknownAnswerKey }
        answer.should be_present
        answer[:responses].should == 1
      end

      it 'should count those who did not fill in any answer' do
        stats = subject.run([
          {
            answer_for_color1: "",
            answer_id_for_color1: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:id] == FIMB::MissingAnswerKey }
        answer.should be_present
        answer[:responses].should == 1
      end

      it 'should not generate the unknown or missing answers unless needed' do
        stats = subject.run([
          {
            answer_for_color1: "Red",
            answer_id_for_color1: "9711"
          }
        ])

        stats[:answer_sets].detect { |as| as[:text] == 'color1' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == FIMB::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == FIMB::MissingAnswerKey }

          unknown_answer.should_not be_present
          missing_answer.should_not be_present
        end

        stats[:answer_sets].detect { |as| as[:text] == 'color2' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == FIMB::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == FIMB::MissingAnswerKey }

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
          answer_id_for_color1: "9711"
        }
      ])

      stats[:responses].should == 1
    end

    it 'should not count students who didnt' do
      subject.run([{}])[:responses].should == 0
    end

    it "should not consider an answer to be present if it's empty" do
      subject.run([{
        answer_for_color: ''
      }])[:responses].should == 0

      subject.run([{
        answer_for_color: nil
      }])[:responses].should == 0
    end
  end

  describe '[:answered]' do
    it 'should count students who have filled every blank' do
      stats = subject.run([
        {
          answer_id_for_color1: "9711",
          answer_id_for_color2: "9702"
        }
      ])

      stats[:answered].should == 1
    end

    it 'should count students who have filled every blank, even if incorrectly' do
      stats = subject.run([
        {
          answer_for_color1: 'foo',
          answer_for_color2: 'bar'
        }
      ])

      stats[:answered].should == 1
    end

    it 'should not count a student who has left any blank' do
      stats = subject.run([
        {
          answer_for_color1: "purple"
        }
      ])

      stats[:answered].should == 0
    end
  end
end
