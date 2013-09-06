module QuizQuestion::AnswerParsers
  class ShortAnswer < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch(:id, nil),
          text: fields.fetch_with_enforced_length(:answer_text),
          comments: fields.fetch_with_enforced_length(:answer_comments),
          weight: 100
        }

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end
