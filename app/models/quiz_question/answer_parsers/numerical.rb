module QuizQuestion::AnswerParsers
  class Numerical < AnswerParser
    def parse(question)
      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)

        a = {
          id: fields.fetch(:id, nil),
          text: fields.fetch_with_enforced_length(:answer_text),
          comments: fields.fetch_with_enforced_length(:answer_comments),
          weight: 100
        }

        a[:numerical_answer_type] = fields.fetch(:numerical_answer_type)

        if a[:numerical_answer_type] == "exact_answer"
          a[:exact] = fields.fetch(:answer_exact).to_f
          a[:margin] = fields.fetch(:answer_error_margin).to_f
        else
          a[:numerical_answer_type] = "range_answer"
          a[:start] = fields.fetch(:answer_range_start).to_f
          a[:end] = fields.fetch(:answer_range_end).to_f
        end

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end

      question.answers = @answers
      question
    end
  end
end

