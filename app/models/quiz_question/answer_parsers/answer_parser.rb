module QuizQuestion::AnswerParsers
  class AnswerParser
    def initialize(answers)
      @answers = answers
    end

    def parse(question)
      question.answers = @answers
      question
    end
  end
end
