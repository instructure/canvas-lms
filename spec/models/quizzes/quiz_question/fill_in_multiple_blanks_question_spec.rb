require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::FillInMultipleBlanksQuestion do

  let(:answer1) { {id: 1, blank_id: 'blank1', text: 'First', weight: 100} }
  let(:answer2) { {id: 2, blank_id: 'blank2', text: 'Second', weight: 100} }
  let(:question) { Quizzes::QuizQuestion::FillInMultipleBlanksQuestion.new(answers: [answer1, answer2]) }

  describe "#find_chosen_answer" do
    it "should compare answers in downcase" do
      expect(question.find_chosen_answer('blank1', 'FIRST')[:id]).to eq answer1[:id]
    end

    it "should only consider answers for the same blank" do
      expect(question.find_chosen_answer('blank1', 'Second')[:id]).to be_nil
    end

    it "should retain the casing in the provided response for correct answers" do
      expect(question.find_chosen_answer('blank1', 'FIRST')[:text]).to eq 'FIRST'
    end

    it "should not alter the answer object's casing in correct answers" do
      question.find_chosen_answer('blank1', 'FIRST')
      expect(answer1[:text]).to eq 'First'
    end

    it "should retain the casing in the provided response for incorrect answers" do
      expect(question.find_chosen_answer('blank1', 'Wrong')[:text]).to eq 'Wrong'
    end

    it "should replace nil with an empty string" do
      expect(question.find_chosen_answer('blank1', nil)[:text]).to eq ''
    end
  end
end
