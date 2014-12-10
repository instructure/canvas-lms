module Quizzes::QuizQuestion::AnswerSerializers
  class Numerical < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # Serialize a decimal answer.
    #
    # @param [BigDecimal|String] answer
    #
    # @note
    #   This serializer does not reject any input but instead coerces everything
    #   to a BigDecimal, even if the input is not a number.
    #
    # @example acceptable inputs
    #  { answer: 1 }
    #  { answer: 2.3e-6 }
    #  { answer: "8.4" }
    #
    # @example outputs, respectively from above
    #  { question_5: 1 }
    #  { question_5: 2.3e-6 }
    #  { question_5: 8.4 }
    def serialize(answer)
      rc = SerializedAnswer.new
      rc.answer[question_key] = Util.to_decimal(answer).to_s
      rc
    end

    # @return [BigDecimal|NilClass]
    def deserialize(submission_data, full=false)
      answer = submission_data[question_key]

      if answer.present?
        Util.to_decimal(answer.to_s)
      end
    end
  end
end
