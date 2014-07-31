require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/common.rb')

describe Quizzes::QuizStatistics::ItemAnalysis::Item do
  describe ".from" do
    it "should create an item for a supported question type" do
      qq = {:question_type => "true_false_question", :answers => []}
      Quizzes::QuizStatistics::ItemAnalysis::Item.from(nil, qq).should_not be_nil
    end

    it "should not create an item for an unsupported question type" do
      qq = {:question_type => "essay_question"}
      Quizzes::QuizStatistics::ItemAnalysis::Item.from(nil, qq).should be_nil
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
      item.num_respondents.should == 3 # one guy didn't answer
    end

    it "should return correct respondents" do
      item.num_respondents(:correct).should == 2
    end

    it "should return incorrect respondents" do
      item.num_respondents(:incorrect).should == 1
    end

    it "should return respondents in a certain bucket" do
      item.num_respondents(:top).should == 1
      item.num_respondents(:middle).should == 2
      item.num_respondents(:bottom).should == 0 # there is a guy, but he didn't answer this question
    end

    it "should correctly evaluate multiple filters" do
      item.num_respondents(:top, :correct).should == 1
      item.num_respondents(:top, :incorrect).should == 0
      item.num_respondents(:middle, :correct).should == 1
      item.num_respondents(:middle, :incorrect).should == 1
    end
  end

  describe "#variance" do
    it "should match R's output" do
      # population variance, not sample variance (thus the adjustment)
      # > v <- c(1, 1, 0)
      # > var(v)*2/3
      # [1] 0.2222222
      item.variance.should be_approximately 0.2222222
    end
  end

  describe "#standard_deviation" do
    it "should match R's output" do
      # population sd, not sample sd (thus the adjustment)
      # > v <- c(1, 1, 0)
      # > sqrt(var(v)/3*2)
      # [1] 0.4714045
      item.standard_deviation.should be_approximately 0.4714045
    end
  end

  describe "#difficulty_index" do
    it "should return the ratio of correct to incorrect" do
      item.difficulty_index.should be_approximately 0.6666667
    end
  end

  describe "#point_biserials" do
    # > x<-c(3,2,2)
    # > cor(x,c(1,1,0))
    # [1] 0.5
    # > cor(x,c(0,0,1))
    # [1] -0.5
    it "should match R's output" do
      item.point_biserials.should be_approximately [0.5, -0.5, nil, nil]
    end
  end
end
