module Quizzes::QuizQuestion::AnswerSerializers
  class MultipleAnswers < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # Serialize a selection, a set of answer IDs.
    #
    # Serialization request will be rejected if:
    #
    #   - the selection is not an Array
    #   - the selection contains a bad or unknown answer id
    #
    # @example selection for two answers with id 5 and 8:
    #   [ 5, 8 ]
    #
    # @param answer_ids [Array<Integer>]
    #   The selected answer IDs.
    #
    # @example Answers 5 and 8 are selected, answer#9 isn't in QuizQuestion#1:
    #   {
    #     question_1_answer_5: "1",
    #     question_1_answer_8: "1",
    #     question_1_answer_9: "0"
    #   }
    def serialize(selection)
      rc = SerializedAnswer.new

      unless selection.is_a?(Array)
        return rc.reject :invalid_type, 'answer', Array
      end

      selection.each_with_index do |answer_id, index|
        answer_id = Util.to_integer(answer_id)

        if answer_id.nil?
          return rc.reject :invalid_type, "answer[#{index}]", Integer
        elsif !answer_available?(answer_id)
          return rc.reject :unknown_answer, answer_id
        end
      end

      selection = selection.map(&:to_i)

      answer_ids.each_with_object(rc.answer) do |answer_id, out|
        is_selected = selection.include?(answer_id)
        out[answer_key(answer_id)] = answer_value(is_selected)
      end

      rc
    end

    # @return [Array<String>]
    #   IDs of the selected answers.
    #
    # @example output for answers 5 and 8 selected:
    #   [ "5", "8" ]
    #
    # @example output for no answers selected:
    #   []
    def deserialize(submission_data, full=false)
      answers.each_with_object([]) do |answer_record, out|
        answer_id = answer_record[:id]

        is_selected = submission_data[answer_key(answer_id)]
        is_selected = Util.to_boolean(is_selected)

        if is_selected
          out << answer_id.to_s
        end
      end
    end

    private

    def answer_key(answer_id)
      [ question_key, 'answer', answer_id ].join('_')
    end

    # Using anything other than "1" and "0" to indicate whether the answer is
    # selected won't work with the current UI.
    def answer_value(is_on)
      is_on ? "1" : "0"
    end
  end
end
