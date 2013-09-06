module QuizQuestion::AnswerParsers
  class Matching < AnswerParser
    def parse(question)
      question[:matches] = []

      @answers.map! do |answer_group, answer|
        fields = QuizQuestion::RawFields.new(answer)
        a = {
          id: fields.fetch(:id, nil),
          text: fields.fetch_with_enforced_length(:answer_match_left),
          left: fields.fetch_with_enforced_length(:answer_match_left),
          right: fields.fetch_with_enforced_length(:answer_match_right),
          comments: fields.fetch_with_enforced_length(:answer_comments)
        }

        a[:left_html] = a[:html] = fields.sanitize(fields.fetch(:answer_match_left_html)) if answer[:answer_match_left_html].present?

        a[:match_id] = answer[:match_id].to_i

        answer = QuizQuestion::AnswerGroup::Answer.new(a)

        answer_group.taken_ids << answer.set_match_id(answer_group.taken_ids)
        answer_group.taken_ids << answer.set_id(answer_group.taken_ids)

        question[:matches] << {match_id: a[:match_id], text: a[:right] }

        answer
      end
      question[:matching_answer_incorrect_matches].split("\n").each do |other|
        fields = QuizQuestion::RawFields.new({distractor: other[0..255]})
        question.match_group.add(text: fields.fetch_with_enforced_length(:distractor))
      end

      question[:matches] = question.match_group.to_a
      question.answers = @answers

      question
    end

  end
end

