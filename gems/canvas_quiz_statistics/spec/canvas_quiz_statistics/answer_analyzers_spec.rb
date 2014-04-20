require 'spec_helper'

describe CanvasQuizStatistics::AnswerAnalyzers do
  Analyzers = CanvasQuizStatistics::AnswerAnalyzers

  describe '[]' do
    it 'should locate an analyzer' do
      subject['essay_question'].should == Analyzers::Essay
    end

    it 'should return the generic analyzer for questions of unsupported types' do
      subject['text_only_question'].should == Analyzers::Base
    end
  end
end
