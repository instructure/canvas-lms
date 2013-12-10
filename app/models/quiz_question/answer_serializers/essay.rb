module QuizQuestion::AnswerSerializers
  class Essay < AnswerSerializer

    # @param answer_html [String]
    #   The textual/HTML answer. Will be HTML escaped.
    #
    # @example output for an answer for QuizQuestion#1
    #  {
    #    :question_1 => "&lt;p&gt;Hello World!&lt;/p&gt;"
    #  }
    def serialize(answer_html)
      rc = SerializedAnswer.new

      unless answer_html.is_a?(String)
        return rc.reject :invalid_type, 'answer', String
      end

      answer_html = Util.sanitize_html answer_html

      if Util.text_too_long?(answer_html)
        return rc.reject :text_too_long
      end

      rc.answer[question_key] = answer_html
      rc
    end

    # @return [String]
    #   The HTML-escaped textual answer.
    def deserialize(submission_data)
      submission_data[question_key]
    end
  end
end