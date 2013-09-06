module QuizQuestion::AnswerParsers
  class MultipleDropdowns < AnswerParser
    def parse(question)
      variables = HashWithIndifferentAccess.new

      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)

        a = {
            id: fields.fetch(:id, nil),
            text: fields.fetch_with_enforced_length(:answer_text),
            comments: fields.fetch_with_enforced_length(:answer_comments),
            weight: fields.fetch(:answer_weight, 0).to_f,
            blank_id: fields.fetch_with_enforced_length(:blank_id)
        }

        answer = QuizQuestion::AnswerGroup::Answer.new(a)
        variables[answer[:blank_id]] ||= false
        variables[answer[:blank_id]] = true if answer.correct?

        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)
        answer
      end
      question.answers = @answers

      variables.each do |variable, found_correct|
        if !found_correct
          question.answers.each_with_index do |answer, idx|
            if answer[:blank_id] == variable && !found_correct
              question.answers[idx][:weight] = 100
              found_correct = true
            end
          end

        end
      end

      question
    end
  end
end
