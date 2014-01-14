module QuizQuestion::AnswerParsers
  class Essay < AnswerParser
    def parse(question)
      comment = @answers[0][:answer_comments] rescue ""
      answer = QuizQuestion::RawFields.new({comments:comment})
      question[:comments] = answer.fetch_with_enforced_length(:comments, max_size: 5.kilobyte)

      question.answers = @answers
      question
    end
  end
end
