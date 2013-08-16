require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe QuizStatistics::ItemAnalysis::Summary do
  let(:summary) {
    simple_quiz_with_submissions %w{T T A}, %w{T T A}, %w{T T B}, %w{T F B}, %w{T F B}
    QuizStatistics::ItemAnalysis::Summary.new(@quiz)
  }

  describe "#aggregate_data" do
    it "should group items by question" do
      simple_quiz_with_shuffled_answers %w{T T A}, %w{T T A}, %w{T T B}, %w{T F B}, %w{T F B}
      summary = QuizStatistics::ItemAnalysis::Summary.new(@quiz)
      summary.size.should == 3
    end
  end

  describe "#add_response" do
    it "should not add unsupported response types" do
      summary.add_response({:question_type => "foo", :answers => []}, 0, 0)
      summary.size.should == 3
    end
  end

  describe "#each" do
    it "should yield each item" do
      count = 0
      summary.each do |item|
        item.should be_a QuizStatistics::ItemAnalysis::Item
        count += 1
      end
      count.should == 3
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
      summary.alpha.should be_approximately 0.545
    end

    it "should be nil if #variance is 0" do
      summary.stubs(:variance).returns(0)
      summary.alpha.should be_nil
    end
  end

  describe "#variance" do
    it "should match R's output" do
      # population variance, not sample variance (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > var(v)*3/4
      # [1] 0.6875
      summary.variance.should be_approximately 0.6875
    end
  end

  describe "#standard_deviation" do
    it "should match R's output" do
      # population sd, not sample sd (thus the adjustment)
      # > v <- c(3, 2, 1, 1)
      # > sqrt(var(v)*3/4)
      # [1] 0.8291562
      summary.standard_deviation.should be_approximately 0.8291562
    end
  end
end
