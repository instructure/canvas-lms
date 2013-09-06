module QuizQuestion::AnswerParsers
  class MissingWord < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          text: fields.fetch_with_enforced_length(:answer_text),
          comments: fields.fetch_with_enforced_length(:answer_comments),
          weight: fields.fetch(:answer_weight).to_f
        }

        id = fields.fetch(:id, nil)
        id = id.to_i if id
        a[:id] = id

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      @answers.set_correct_if_none
      fields = QuizQuestion::RawFields.new({text_after_answers: question[:text_after_answers]})
      question[:text_after_answers] = fields.sanitize(fields.fetch_with_enforced_length(:text_after_answers, max_size: 16.kilobyte))

      question.answers = @answers
      question
    end
  end
end

