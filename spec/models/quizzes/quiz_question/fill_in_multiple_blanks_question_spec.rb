require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::FillInMultipleBlanksQuestion do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let(:answer1) { {id: 1, blank_id: 'blank1', text: 'First', weight: 100} }
  let(:answer2) { {id: 2, blank_id: 'blank2', text: 'Second', weight: 100} }
  let(:question) { Quizzes::QuizQuestion::FillInMultipleBlanksQuestion.new(answers: [answer1, answer2]) }

  describe "#find_chosen_answer" do
    it "should compare answers in downcase" do
      question.find_chosen_answer('blank1', 'FIRST')[:id].should == answer1[:id]
    end

    it "should only consider answers for the same blank" do
      question.find_chosen_answer('blank1', 'Second')[:id].should be_nil
    end

    it "should retain the casing in the provided response for correct answers" do
      question.find_chosen_answer('blank1', 'FIRST')[:text].should == 'FIRST'
    end

    it "should not alter the answer object's casing in correct answers" do
      question.find_chosen_answer('blank1', 'FIRST')
      answer1[:text].should == 'First'
    end

    it "should retain the casing in the provided response for incorrect answers" do
      question.find_chosen_answer('blank1', 'Wrong')[:text].should == 'Wrong'
    end

    it "should replace nil with an empty string" do
      question.find_chosen_answer('blank1', nil)[:text].should == ''
    end
  end
end
