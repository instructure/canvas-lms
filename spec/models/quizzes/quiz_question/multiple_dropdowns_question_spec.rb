require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::QuizQuestion::MultipleDropdownsQuestion do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  let(:question_data) do
    {
      :id => "1",
      :answers => [{:id => 2, :blank_id => "test_group", :wieght => 100}]
    }
  end

  let(:question) do
    Quizzes::QuizQuestion::MultipleDropdownsQuestion.new(question_data)
  end

  describe "#initialize" do
    it "assign question data" do
      question.question_id.should == question_data[:id]
    end
  end

  describe "#find_chosen_answer" do
    it 'detects answers when answer id is an integer' do
      answer = question.find_chosen_answer('test_group', '2')
      answer[:id].should == question_data[:answers][0][:id]
      answer[:blank_id].should == question_data[:answers][0][:blank_id]
    end

    it 'detects answers when answer id is a string' do
      question_data[:answers][0][:id] = "3"
      question = Quizzes::QuizQuestion::MultipleDropdownsQuestion.new(question_data)
      answer = question.find_chosen_answer('test_group', '3')
      answer[:id].should == question_data[:answers][0][:id]
      answer[:blank_id].should == question_data[:answers][0][:blank_id]
    end

    it 'returns nil values when answer not detected' do
      answer = question.find_chosen_answer('test_group', '0')
      answer[:id].should be nil
      answer[:blank_id].should be nil
    end
  end
end
