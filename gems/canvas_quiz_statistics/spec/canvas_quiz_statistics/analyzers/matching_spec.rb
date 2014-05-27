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
      subject.run([{ answer_8796: "4393" }])[:responses].should == 1
    end

    it "should not count students who didn't make any match" do
      subject.run([{}])[:responses].should == 0

      # empty match id
      subject.run([{ answer_8796: "" }])[:responses].should == 0

      # unknown match id
      subject.run([{ answer_8796: "1234" }])[:responses].should == 0

      # unknown answer
      subject.run([{ answer_5555: "4393" }])[:responses].should == 0
    end
  end

  describe '[:answered]' do
    it 'should count students who matched everything' do
      subject.run([
        correct_answer
      ])[:answered].should == 1
    end

    it 'should count students who matched everything even if incorrectly' do
      subject.run([
        partially_correct_answer
      ])[:answered].should == 1
    end

    it "should not count students who skipped at least one matching" do
      subject.run([
        {
          answer_8796: "1525",
          answer_6666: "4393",
        }
      ])[:answered].should == 0
    end
  end

  describe '[:answer_sets]' do
    it 'should break down every answer against all possible matches' do
      stats = subject.run([])
      stats[:answer_sets].should be_present
      stats[:answer_sets].length.should == 3
      stats[:answer_sets].first.tap do |set|
        set[:answers].should be_present
        set[:answers].length.should == 5
      end
    end

    describe '[][:answers][:responses]' do
      it 'should count all students who attempted to match the blank' do
        stats = subject.run([
          { answer_8796: '1525' }
        ])

        stats[:answer_sets].detect { |set| set[:id] == '8796' }.tap do |set|
          set[:answers].detect { |lhs| lhs[:id] == '1525' }.tap do |lhs|
            lhs[:responses].should == 1
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
      lhs.should be_present
      lhs[:responses].should == 1
    end
  end

  it_behaves_like '[:correct]'
  it_behaves_like '[:partially_correct]'
  it_behaves_like '[:incorrect]'
end
