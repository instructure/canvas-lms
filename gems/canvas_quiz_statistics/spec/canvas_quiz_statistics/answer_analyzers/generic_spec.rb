require 'spec_helper'

describe CanvasQuizStatistics::AnswerAnalyzers::Base do
  describe '#run' do
    it 'returns an empty set' do
      subject.run({}, []).should == {}
    end
  end

  describe '#answer_present?' do
    it 'defaults to testing whether :text is present' do
      subject.answer_present?({ text: 'foo' }).should be_true
      subject.answer_present?({}).should be_false
      subject.answer_present?({ text: nil }).should be_false
    end
  end
end