module QuizQuestion::AnswerParsers
  class FillInMultipleBlanks < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)

        answer = QuizQuestion::AnswerGroup::Answer.new({
          id: fields.fetch_any(:id, nil),
          text: fields.fetch_with_enforced_length([:answer_text, :text]),
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          weight: fields.fetch_any([:answer_weight, :weight]).to_f,
          blank_id: fields.fetch_with_enforced_length(:blank_id)
        })

        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end
