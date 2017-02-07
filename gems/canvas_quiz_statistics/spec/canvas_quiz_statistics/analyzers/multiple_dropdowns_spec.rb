require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleDropdowns do
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
        expect(answer[:responses]).to eq(1)
      end

      it 'should stringify ids' do
        stats = subject.run([
          {
            answer_id_for_organ: 3208
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == '3208' }
        expect(answer[:responses]).to eq(1)
      end

      it 'should count those who filled in an unknown answer' do
        stats = subject.run([
          {
            answer_id_for_organ: '1234'
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }
        expect(answer).to be_present
        expect(answer[:responses]).to eq(1)
      end

      it 'should count those who did not fill in any answer' do
        stats = subject.run([
          {
            answer_id_for_organ: nil
          }
        ])

        answer_set = stats[:answer_sets].detect { |as| as[:text] == 'organ' }
        answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }
        expect(answer).to be_present
        expect(answer[:responses]).to eq(1)
      end

      it 'should not generate the unknown or missing answers unless needed' do
        stats = subject.run([
          { answer_id_for_organ: "3208" }
        ])

        stats[:answer_sets].detect { |as| as[:text] == 'organ' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          expect(unknown_answer).not_to be_present
          expect(missing_answer).not_to be_present
        end

        stats[:answer_sets].detect { |as| as[:text] == 'color' }.tap do |answer_set|
          unknown_answer = answer_set[:answers].detect { |a| a[:id] == Constants::UnknownAnswerKey }
          missing_answer = answer_set[:answers].detect { |a| a[:id] == Constants::MissingAnswerKey }

          expect(unknown_answer).not_to be_present
          expect(missing_answer).to be_present
          expect(missing_answer[:responses]).to eq(1)
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

      expect(stats[:correct]).to eq(2)
    end
  end

  describe '[:partial]' do
    it 'should count all partially correct responses' do
      stats = subject.run([
        { correct: "true" },
        { correct: "partial" }
      ])

      expect(stats[:partially_correct]).to eq(1)
    end
  end

  describe '[:incorrect]' do
    it 'should count all incorrect responses' do
      stats = subject.run([
        { correct: nil },
        { correct: false }
      ])

      expect(stats[:incorrect]).to eq(2)
    end
  end

  describe '[:responses]' do
    it 'should count all students who have filled any blank' do
      stats = subject.run([
        {
          answer_id_for_organ: '3208'
        }
      ])

      expect(stats[:responses]).to eq(1)
    end

    it 'should not count students who didnt' do
      expect(subject.run([{}])[:responses]).to eq(0)
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

      expect(stats[:answered]).to eq(1)
    end

    it 'should count students who have filled every blank, even if incorrectly' do
      stats = subject.run([
        {
          answer_id_for_organ: '8331',
          answer_id_for_color: '1638'
        }
      ])

      expect(stats[:answered]).to eq(1)
    end

    it 'should not count a student who has left any blank' do
      stats = subject.run([
        {
          answer_for_color: '1381'
        }
      ])

      expect(stats[:answered]).to eq(0)
    end
  end
end
