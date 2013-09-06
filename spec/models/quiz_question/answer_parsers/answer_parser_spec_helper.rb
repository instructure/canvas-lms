Spec::Matchers.define :have_answer do |expected|
  match do |actual|
    expected = Regexp.new(expected, "i") if expected.is_a? String

    actual.detect { |a| a[:text] =~ expected || a[:html] =~ expected || a[:comments] =~ expected || a[:answer] =~ expected }
  end
end

shared_examples_for "All answer parsers" do
  before(:each) do
    question = QuizQuestion::QuestionData.new(question_params)
    question.answers = QuizQuestion::AnswerGroup.new(raw_answers)
    parser = parser_class.new(question.answers)
    question = parser.parse(question)
    @answer_data = question.answers
  end

  it "seeds the question with the answers" do
    @answer_data.answers.should have(raw_answers.size).items
  end

  it "formats the answers" do
    @answer_data.should be_kind_of(QuizQuestion::AnswerGroup)
    raw_answers.each do |raw|
      @answer_data.answers.should have_answer raw[:answer_text]
    end
  end

  it "provides IDs for the answers" do
    ids = @answer_data.answers.map { |a| a[:id] }
    ids.each { |id| id.should be_kind_of(Fixnum) }
  end
end


