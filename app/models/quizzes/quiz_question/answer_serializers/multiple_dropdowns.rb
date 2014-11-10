module Quizzes::QuizQuestion::AnswerSerializers
  class MultipleDropdowns < FillInMultipleBlanks
    protected

    # Rejects if the answer id is bad or doesn't identify a known answer
    def validate_blank_answer(blank, answer_id, rc)
      answer_id = Util.to_integer answer_id

      if answer_id.nil?
        rc.reject :invalid_type, "answer.#{blank}", Integer
      elsif !answer_available? answer_id
        rc.reject :unknown_answer, answer_id
      end
    end

    def serialize_blank_answer(answer_id)
      answer_id.to_i.to_s
    end

    def deserialize_blank_answer(answer_id)
      answer_id
    end
  end
end
