module Quizzes::QuizQuestion::AnswerSerializers
  class MultipleChoice < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer

    # Select an answer from the set of available answers.
    #
    # Serialization request will be rejected if:
    #
    #   - the answer id is bad or unknown
    #
    # @example input where the answer ID is 123
    # {
    #   answer: 123
    # }
    #
    # @example output where the question ID is 5
    # {
    #   question_5_answer: "123"
    # }
    def serialize(answer_id)
      rc = SerializedAnswer.new
      answer_id = Util.to_integer answer_id

      if answer_id.nil?
        return rc.reject :invalid_type, 'answer', Integer
      elsif !answer_available? answer_id
        return rc.reject :unknown_answer, answer_id
      end

      rc.answer[question_key] = answer_id.to_s
      rc
    end

    # @return [String]
    #   ID of the selected answer.
    #
    # @example output for answer #3 selected:
    #   "3"
    def deserialize(submission_data, full=false)
      submission_data[question_key]
    end
  end
end
