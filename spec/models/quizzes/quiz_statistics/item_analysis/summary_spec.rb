require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe Quizzes::QuizStatistics::ItemAnalysis::Summary do

  before(:once) {
    simple_quiz_with_submissions %w{T T A}, %w{T T A}, %w{T T B}, %w{T F B}, %w{T F B}
  }
  let(:summary) {
    Quizzes::QuizStatistics::ItemAnalysis::Summary.new(@quiz)
  }

  describe "#aggregate_data" do
    it "should group items by question" do
      simple_quiz_with_shuffled_answers %w{T T A}, %w{T T A}
      summary = Quizzes::QuizStatistics::ItemAnalysis::Summary.new(@quiz)
      expect(summary.size).to eq 3
    end
  end

  describe "#buckets" do
    it "distributes the students accordingly" do
      simple_quiz_with_submissions %w{T T A},
        %w{T T A},%w{T T A},%w{T T B}, # top
        %w{T F B},%w{T F B},%w{F T C},%w{F T D},%w{F T B}, # middle
        %w{F F B},%w{F F C},%w{F F D} # bottom

      summary = Quizzes::QuizStatistics::ItemAnalysis::Summary.new(@quiz)
      buckets = summary.buckets
      total = buckets.values.map(&:size).sum
      top, middle, bottom = buckets[:top].size/total.to_f, buckets[:middle].size/total.to_f, buckets[:bottom].size/total.to_f

      # because of the small sample size, this is slightly off, but close enough for gvt work
      expect(top).to be_approximately 0.27, 0.03
      expect(middle).to be_approximately 0.46, 0.06
      expect(bottom).to be_approximately 0.27, 0.03
    end
  end

  describe "#add_response" do
    it "should not add unsupported response types" do
      summary.add_response({:question_type => "foo", :answers => []}, 0, 0)
      expect(summary.size).to eq 3
    end
  end

  describe "#each" do
    it "should yield each item" do
      count = 0
      summary.each do |item|
        expect(item).to be_a Quizzes::QuizStatistics::ItemAnalysis::Item
        count += 1
      end
      expect(count).to eq 3
    end
  end

  describe "#alpha" do
    it "should match R's output" do
      # > mdat <- matrix(c(1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0), nrow=4)
      # > cronbach.alpha(mdat)
      #
      # Cronbach's alpha for the 'mdat' data-set
      #
      # Items: 3
      # Sample units: 4
      # alpha: 0.545
      expect(summary.alpha).to be_approximately 0.545
    end

    it "should be nil if #variance is 0" do
      summary.stubs(:variance).returns(0)
      expect(summary.alpha).to be_nil
    end
  end

  describe "#variance" do
    it "should match R's output" do
      # population variance, not sample variance (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > var(v)*3/4
      # [1] 0.6875
      expect(summary.variance).to be_approximately 0.6875
    end
  end

  describe "#standard_deviation" do
    it "should match R's output" do
      # population sd, not sample sd (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > sqrt(var(v)*3/4)
      # [1] 0.8291562
      expect(summary.standard_deviation).to be_approximately 0.8291562
    end
  end
end
