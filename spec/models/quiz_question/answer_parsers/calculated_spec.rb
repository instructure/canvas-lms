require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/answer_parser_spec_helper.rb')

describe QuizQuestion::AnswerParsers::Calculated do
  context "#parse" do
    let(:raw_answers) do
      [
        {
          variables: [{name: "x", value: "9"}],
          answer_text: 14
        },
        {
          variables: [{name: "x", value: "6"}],
          answer_text: 11
        },
        {
          variables: [{name: "x", value: "7"}],
          answer_text: 12
        }
      ]
    end
    let(:parser_class) { QuizQuestion::AnswerParsers::Calculated }
    let(:question_params) do
      {
        question_name: "Formula Question",
        question_type: "calculated_question",
        points_possible: 1,
        question_text: "What is 5 + [x]?",
        formulas: ["5+x"],
        variables: [
          { name: "x", min: 5, max: 10, scale: 0 }
        ]
      }
    end

    it "formats formulas for the question"
    it "formats variables for the question"
  end
end
