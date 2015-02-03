require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe Quizzes::QuizStatistics::ItemAnalysis::Item do

  describe ".from" do
    it "should create an item for a supported question type" do
      qq = {:question_type => "true_false_question", :answers => []}
      expect(Quizzes::QuizStatistics::ItemAnalysis::Item.from(nil, qq)).not_to be_nil
    end

    it "should not create an item for an unsupported question type" do
      qq = {:question_type => "essay_question"}
      expect(Quizzes::QuizStatistics::ItemAnalysis::Item.from(nil, qq)).to be_nil
    end
  end

  before(:once) {
    simple_quiz_with_submissions %w{T T A}, %w{T T A}, %w{T F A}, %w{T T B}, %w{T T}
  }
  let(:item) {
    @summary = Quizzes::QuizStatistics::ItemAnalysis::Summary.new(@quiz)
    @summary.sorted_items.last
  }

  describe "#num_respondents" do
    it "should return all respondents" do
      expect(item.num_respondents).to eq 3 # one guy didn't answer
    end

    it "should return correct respondents" do
      expect(item.num_respondents(:correct)).to eq 2
    end

    it "should return incorrect respondents" do
      expect(item.num_respondents(:incorrect)).to eq 1
    end

    it "should return respondents in a certain bucket" do
      expect(item.num_respondents(:top)).to eq 1
      expect(item.num_respondents(:middle)).to eq 2
      expect(item.num_respondents(:bottom)).to eq 0 # there is a guy, but he didn't answer this question
    end

    it "should correctly evaluate multiple filters" do
      expect(item.num_respondents(:top, :correct)).to eq 1
      expect(item.num_respondents(:top, :incorrect)).to eq 0
      expect(item.num_respondents(:middle, :correct)).to eq 1
      expect(item.num_respondents(:middle, :incorrect)).to eq 1
    end
  end

  describe "#variance" do
    it "should match R's output" do
      # population variance, not sample variance (thus the adjustment)
      # > v <- c(1, 1, 0)
      # > var(v)*2/3
      # [1] 0.2222222
      expect(item.variance).to be_approximately 0.2222222
    end
  end

  describe "#standard_deviation" do
    it "should match R's output" do
      # population sd, not sample sd (thus the adjustment)
      # > v <- c(1, 1, 0)
      # > sqrt(var(v)/3*2)
      # [1] 0.4714045
      expect(item.standard_deviation).to be_approximately 0.4714045
    end
  end

  describe "#difficulty_index" do
    it "should return the ratio of correct to incorrect" do
      expect(item.difficulty_index).to be_approximately 0.6666667
    end
  end

  describe "#point_biserials" do
    # > x<-c(3,2,2)
    # > cor(x,c(1,1,0))
    # [1] 0.5
    # > cor(x,c(0,0,1))
    # [1] -0.5
    it "should match R's output" do
      expect(item.point_biserials).to be_approximately [0.5, -0.5, nil, nil]
    end
  end
end
