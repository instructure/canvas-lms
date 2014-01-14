require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/answer_parser_spec_helper.rb')


describe QuizQuestion::AnswerParsers::MissingWord do
  describe "#parse" do
    let(:raw_answers) do
      [
        {
          answer_text: "Answer 1",
          answer_comments: "This is answer 1",
          answer_weight: 0,
          text_after_answers: "Text after Answer 1"
        },
        {
          answer_text: "Answer 2",
          answer_comments: "This is answer 2",
          answer_weight: 100,
          text_after_answers: "Text after Answer 2"
        },
        {
          answer_text: "Answer 3",
          answer_comments: "This is answer 3",
          answer_weight: 0,
          text_after_answers: "Text after Answer 3"
        }
      ]
    end

    let(:question_params) { Hash.new }
    let(:parser_class) { QuizQuestion::AnswerParsers::MissingWord }

    context "in general" do
      it_should_behave_like "All answer parsers"
    end

    context "with no answer specified as correct" do
      let(:unspecified_answers) { raw_answers.map { |a| a[:answer_weight] = 0; a } }

      before(:each) do
        question = QuizQuestion::QuestionData.new({})
        question.answers = QuizQuestion::AnswerGroup.new(unspecified_answers)
        parser = QuizQuestion::AnswerParsers::MissingWord.new(question.answers)
        question = parser.parse(question)
        @answer_data = question.answers
      end

      it "defaults to the first answer being correct" do
        @answer_data.answers.first[:weight].should == 100
      end

    end

  end
end
