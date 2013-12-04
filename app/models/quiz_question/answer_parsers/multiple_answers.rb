module QuizQuestion::AnswerParsers
  class MultipleAnswers < AnswerParser
    def parse(question)

      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch(:id, nil),
          text: fields.fetch_with_enforced_length(:answer_text),
          comments: fields.fetch_with_enforced_length(:answer_comments),
          weight: answer.fetch(:answer_weight).to_f
        }

        a[:html] = fields.sanitize(fields.fetch(:answer_html)) if fields.fetch(:answer_html).present?

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
