require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Matching do

  let(:question_data) { QuestionHelpers.fixture('matching_question') }
  let :correct_answer do
    {
      answer_8796: "1525",
      answer_6666: "4393",
      answer_6430: "4573"
    }
  end

  let :partially_correct_answer do
    {
      answer_8796: "4393",
      answer_6666: "1525",
      answer_6430: "4573"
    }
  end

  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { subject.run([]) }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count students who made any match' do
      expect(subject.run([{ answer_8796: "4393" }])[:responses]).to eq(1)
    end

    it "should not count students who didn't make any match" do
      expect(subject.run([{}])[:responses]).to eq(0)

      # empty match id
      expect(subject.run([{ answer_8796: "" }])[:responses]).to eq(0)

      # unknown match id
      expect(subject.run([{ answer_8796: "1234" }])[:responses]).to eq(0)

      # unknown answer
      expect(subject.run([{ answer_5555: "4393" }])[:responses]).to eq(0)
    end
  end

  describe '[:answered]' do
    it 'should count students who matched everything' do
      expect(subject.run([
        correct_answer
      ])[:answered]).to eq(1)
    end

    it 'should count students who matched everything even if incorrectly' do
      expect(subject.run([
        partially_correct_answer
      ])[:answered]).to eq(1)
    end

    it "should not count students who skipped at least one matching" do
      expect(subject.run([
        {
          answer_8796: "1525",
          answer_6666: "4393",
        }
      ])[:answered]).to eq(0)
    end
  end

  describe '[:answer_sets]' do
    it 'should break down every answer against all possible matches' do
      stats = subject.run([])
      expect(stats[:answer_sets]).to be_present
      expect(stats[:answer_sets].length).to eq(3)
      stats[:answer_sets].first.tap do |set|
        expect(set[:answers]).to be_present
        expect(set[:answers].length).to eq(5)
      end
    end

    describe '[][:answers][:responses]' do
      it 'should count all students who attempted to match the blank' do
        stats = subject.run([
          { answer_8796: '1525' }
        ])

        stats[:answer_sets].detect { |set| set[:id] == '8796' }.tap do |set|
          set[:answers].detect { |lhs| lhs[:id] == '1525' }.tap do |lhs|
            expect(lhs[:responses]).to eq(1)
          end
        end
      end
    end

    it 'should generate a NoAnswer for those who didnt make any match' do
      stats = subject.run([
        {}
      ])

      set = stats[:answer_sets].detect { |set| set[:id] == '8796' }
      lhs = set[:answers].detect { |lhs| lhs[:id] == 'none' }
      expect(lhs).to be_present
      expect(lhs[:responses]).to eq(1)
    end
  end

  it_behaves_like '[:correct]'
  it_behaves_like '[:partially_correct]'
  it_behaves_like '[:incorrect]'
end
