module QuizQuestion::AnswerParsers
  class TrueFalse < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          comments: fields.fetch_with_enforced_length([:answer_comment, :comments]),
          text: fields.fetch_any([:answer_text, :text]),
          weight: fields.fetch_any([:answer_weight, :weight]).to_i
        }

        id = fields.fetch_any([:id, :answer_id], nil)
        id = id.to_i if id
        a[:id] = id

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end


