module QuizQuestion::AnswerParsers
  class MultipleChoice < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)

        id = fields.fetch_any([:id, :answer_id], nil)
        id = id.to_i if id
        text = fields.fetch_with_enforced_length([:answer_text, :text])
        comments = fields.fetch_with_enforced_length([:answer_comment, :comments])
        weight = fields.fetch_any([:answer_weight, :weight]).to_f
        html = fields.sanitize(fields.fetch_any([:answer_html, :html]))

        answer = QuizQuestion::AnswerGroup::Answer.new(id: id, text: text, html: html, comments: comments, weight: weight)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end
      @answers.set_correct_if_none

      question.answers = @answers
      question
    end
  end
end

