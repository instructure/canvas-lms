require 'spec_helper'

describe CanvasQuizStatistics::Analyzers do
  Analyzers = CanvasQuizStatistics::Analyzers

  describe '[]' do
    it 'should locate an analyzer' do
      expect(subject['essay_question']).to eq(Analyzers::Essay)
    end

    it 'should return the generic analyzer for questions of unsupported types' do
      expect(subject['text_only_question']).to eq(Analyzers::Base)
    end
  end
end
