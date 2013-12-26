module QuizQuestion::AnswerParsers
  class MultipleAnswers < AnswerParser
    def parse(question)

      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch_any(:id, nil),
          text: fields.fetch_with_enforced_length([:answer_text, :text]),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          weight: fields.fetch_any([:answer_weight, :weight]).to_f
        }

        a[:html] = fields.sanitize(fields.fetch_any(:answer_html)) if fields.fetch_any(:answer_html).present?

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      @answers.set_correct_if_none

      question.answers = @answers
      question
    end
  end
end
