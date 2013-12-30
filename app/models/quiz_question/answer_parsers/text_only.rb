module QuizQuestion::AnswerParsers
  class TextOnly < AnswerParser
    def parse(question)
     question[:points_possible] = 0
     question
    end
  end
end
