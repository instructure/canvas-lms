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
      expect(question.question_id).to eq question_data[:id]
    end
  end

  describe "#find_chosen_answer" do
    it 'detects answers when answer id is an integer' do
      answer = question.find_chosen_answer('test_group', '2')
      expect(answer[:id]).to eq question_data[:answers][0][:id]
      expect(answer[:blank_id]).to eq question_data[:answers][0][:blank_id]
    end

    it 'detects answers when answer id is a string' do
      question_data[:answers][0][:id] = "3"
      question = Quizzes::QuizQuestion::MultipleDropdownsQuestion.new(question_data)
      answer = question.find_chosen_answer('test_group', '3')
      expect(answer[:id]).to eq question_data[:answers][0][:id]
      expect(answer[:blank_id]).to eq question_data[:answers][0][:blank_id]
    end

    it 'returns nil values when answer not detected' do
      answer = question.find_chosen_answer('test_group', '0')
      expect(answer[:id]).to be nil
      expect(answer[:blank_id]).to be nil
    end
  end
end
