require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/answer_parser_spec_helper.rb')

describe QuizQuestion::AnswerParsers::Essay do
  describe "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Essay Answer",
          answer_comments: "This is an essay answer"
        }
      ]
    end

    let(:parser_class) { QuizQuestion::AnswerParsers::Essay }
    let(:question_params) { Hash.new }

    it "seeds a question with comments" do
      essay = QuizQuestion::AnswerParsers::Essay.new(raw_answers)
      question = QuizQuestion::QuestionData.new({})
      essay.parse(question)
      question[:comments].should == raw_answers[0][:answer_comments]
    end
  end
end
