require 'spec_helper'

describe CanvasQuizStatistics::Analyzers do
  Analyzers = CanvasQuizStatistics::Analyzers

  describe '[]' do
    it 'should locate an analyzer' do
      subject['essay_question'].should == Analyzers::Essay
    end

    it 'should return the generic analyzer for questions of unsupported types' do
      subject['text_only_question'].should == Analyzers::Base
    end
  end
end
