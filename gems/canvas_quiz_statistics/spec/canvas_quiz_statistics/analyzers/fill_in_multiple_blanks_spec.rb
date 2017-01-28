require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::FillInMultipleBlanks do
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
        expect(answer[:responses]).to eq(1)
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
        expect(answer[:responses]).to eq(1)
      end

      it 'should count those who filled in an unknown answer' do
        stats = subject.run([
          {
            answer_for_color1: "purple",
            answer_id_for_color1: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
        expect(answer).to be_present
        expect(answer[:responses]).to eq(1)
      end

      it 'should count those who did not fill in any answer' do
        stats = subject.run([
          {
            answer_for_color1: "",
            answer_id_for_color1: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'color1' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }
        expect(answer).to be_present
        expect(answer[:responses]).to eq(1)
      end

      it 'should not generate the unknown or missing answers unless needed' do
        stats = subject.run([
          {
            answer_for_color1: "Red",
            answer_id_for_color1: "9711"
          }
        ])

        stats[:answer_sets].detect { |as| as[:text] == 'color1' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          expect(unknown_answer).not_to be_present
          expect(missing_answer).not_to be_present
        end

        stats[:answer_sets].detect { |as| as[:text] == 'color2' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          expect(unknown_answer).not_to be_present
          expect(missing_answer).to be_present
          expect(missing_answer[:responses]).to eq(1)
        end
      end
    end
  end

  it_behaves_like '[:correct]'
  it_behaves_like '[:partially_correct]'
  it_behaves_like '[:incorrect]'

  describe '[:responses]' do
    it 'should count all students who have filled any blank' do
      stats = subject.run([
        {
          answer_id_for_color1: "9711"
        }
      ])

      expect(stats[:responses]).to eq(1)
    end

    it 'should not count students who didnt' do
      expect(subject.run([{}])[:responses]).to eq(0)
    end

    it "should not consider an answer to be present if it's empty" do
      expect(subject.run([{
        answer_for_color: ''
      }])[:responses]).to eq(0)

      expect(subject.run([{
        answer_for_color: nil
      }])[:responses]).to eq(0)
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

      expect(stats[:answered]).to eq(1)
    end

    it 'should count students who have filled every blank, even if incorrectly' do
      stats = subject.run([
        {
          answer_for_color1: 'foo',
          answer_for_color2: 'bar'
        }
      ])

      expect(stats[:answered]).to eq(1)
    end

    it 'should not count a student who has left any blank' do
      stats = subject.run([
        {
          answer_for_color1: "purple"
        }
      ])

      expect(stats[:answered]).to eq(0)
    end
  end
end
