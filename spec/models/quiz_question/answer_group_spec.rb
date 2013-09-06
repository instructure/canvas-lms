require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe QuizQuestion::AnswerGroup do
  let(:question_data_params) do
    { 
      answers: [
        {
          answer_text: "A",
          answer_comments: "Comments for A",
          answer_weight: 0,
        },
        {
          answer_text: "B",
          answer_comments: "Comments for B",
          answer_weight: 0,
        },
        {
          answer_text: "C",
          answer_comments: "Comments for C",
          answer_weight: 0,
        }
      ],
      question_type: "multiple_choice_question",
      regrade_option: false,
      points_possible: 5,
      correct_comments: "This question is correct.",
      incorrect_comments: "This question is correct.",
      neutral_comments: "Answer this question.",
      question_name: "Generic question",
      question_text: "What is better, ruby or javascript?"
    }
  end

  let(:question_data) { QuizQuestion::QuestionData.generate(question_data_params) }

  describe ".generate" do
    it "seeds a question with parsed answers" do
      question_data.answers.should be_instance_of(QuizQuestion::AnswerGroup)
      question_data.answers.to_a.size.should == 3
    end
  end

  describe "#to_a" do
    it "returns an array" do
      question_data.answers.to_a.should be_instance_of(Array)
    end

    it "converts each answer to a hash" do
      question_data.answers.to_a.each do |a|
        a.should be_instance_of(Hash)
      end
    end
  end

  describe "#set_correct_if_none" do
    it "sets the first answer to correct if none are set" do
      question_data.answers.set_correct_if_none
      question_data.answers.to_a.first[:weight].should == 100
    end
  end

  describe "#correct_answer" do
    it "returns the correct answer" do
      question_data.answers.correct_answer[:text].should == "A"
    end

  end
end
