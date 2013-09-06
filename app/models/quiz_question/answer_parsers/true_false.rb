module QuizQuestion::AnswerParsers
  class TrueFalse < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          comments: fields.fetch_with_enforced_length(:answer_comments),
          text: fields.fetch(:answer_text),
          weight: fields.fetch(:answer_weight).to_i
        }

        id = fields.fetch(:id, nil)
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


