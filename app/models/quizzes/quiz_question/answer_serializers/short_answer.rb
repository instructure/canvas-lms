module Quizzes::QuizQuestion::AnswerSerializers
  class ShortAnswer < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer

    # Serialize a written, textual answer.
    #
    # Serialization request will be rejected if the answer isn't a string or is
    # too long. See Util#text_too_long?
    #
    # @param answer_hash[:text] String
    #   The textual/HTML answer. Will be text-escaped.
    #
    # @example output for an answer for QuizQuestion#1
    #  {
    #    :question_1 => "sanitized_answer"
    #  }
    def serialize(answer_text)
      rc = SerializedAnswer.new

      if !answer_text.is_a?(String)
        return rc.reject :invalid_type, 'answer', String
      elsif Util.text_too_long? answer_text
        return rc.reject :text_too_long
      end

      rc.answer[question_key] = Util.sanitize_text(answer_text)
      rc
    end

    # @return [String|NilClass] The textual answer, if any.
    def deserialize(submission_data, full=false)
      text = submission_data[question_key]

      if text.nil? || text.empty?
        return nil
      else
        text
      end
    end
  end
end
