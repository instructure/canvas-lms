module Quizzes::QuizQuestion::AnswerSerializers

  # @internal
  # :nodoc:
  #
  # A note on "blanks" to help clear the confusion around their uses, especially
  # in the context of this serializer:
  #
  # There are three distinct versions of an answer's blank used at various
  # stages:
  #
  # 1. the "blank", which is a simple string defined by the teacher when they
  #    created the quiz question, and this is what the API clients are expected
  #    to use for sending answers to that blank
  #
  # 2. the "blank_id": which is a normalized version of the "blank", used
  #    internally to identify the blank (it's a digest), see Util#blank_id
  #    and AssessmentQuestion#variable_id for generating this version
  #
  # 3. the "blank key", which is the key to store the _answer_ to that blank in
  #    a quiz submission's submission_data construct, nobody has to know about
  #    this except for the parsers/serializers
  #
  # Unfortunately, the question_data records refer to the vanilla "blank" as
  # "blank_id", so if you do something like:
  #
  #     qq = quiz.quiz_questions.first # say this is a FIMB question
  #     qq.question_data[:answers][0]
  #
  # You will get a construct with:
  #
  #     { "id"=>"9711", "text"=>"Red", "weight"=>100, "blank_id"=>"color" }
  #
  # Which gave me motive to write this note to help clear up the confusion.
  class FillInMultipleBlanks < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # Accept textual answers for answer blanks.
    #
    # @example input for two blanks, "color1" and "color2":
    #   {
    #     color1: 'red',
    #     color2: 'blue'
    #   }
    #
    # @param [String] answer_hash[:blank]
    #   The textual answer for the given blank. Will be sanitized
    #   (stripped and lowercased).
    #
    # @example output for an answer for QuizQuestion#1 with blank "color":
    #   {
    #     "color" => "red"
    #   }
    def serialize(answer_hash)
      rc = SerializedAnswer.new

      unless answer_hash.is_a?(Hash) || answer_hash.is_a?(ActionController::Parameters)
        return rc.reject :invalid_type, 'answer', Hash
      end

      answer_hash.stringify_keys.each_pair do |blank, answer_text|
        unless blank_available?(blank)
          return rc.reject :unknown_blank, blank
        end

        validate_blank_answer(blank, answer_text, rc)

        unless rc.valid?
          break
        end

        rc.answer[answer_blank_key(blank)] = serialize_blank_answer(answer_text)
      end

      rc
    end

    # @return [Hash{String => String}]
    #   Map of each blank to the text the student filled in.
    #   Value will be null in case the student left the blank empty.
    #
    # @example output for filling in the blank "color" with the text "red"
    #   {
    #     "color": "red"
    #   }
    #
    # @example output for leaving the blank "color" empty, and filling in the
    #          blank "size" with "XL":
    #   {
    #     "color": null,
    #     "size": "XL"
    #   }
    def deserialize(submission_data, full=false)
      answers.each_with_object({}) do |answer_record, out|
        blank = answer_record[:blank_id]
        blank_key = answer_blank_key(blank)
        blank_answer = submission_data[blank_key]

        if blank_answer.present?
          out[blank] = deserialize_blank_answer blank_answer
        elsif full
          out[blank] = nil
        end
      end
    end

    protected

    # Tests that the answer is a string and isn't too long.
    #
    # Override this to provide support for non-textual answers.
    def validate_blank_answer(blank, answer_text, rc)
      if !answer_text.is_a?(String)
        rc.reject :invalid_type, "#{blank}.answer", String
      elsif Util.text_too_long?(answer_text)
        rc.reject :text_too_long
      end
    end

    # Override this to provide support for non-textual answers.
    def serialize_blank_answer(answer_text)
      Util.sanitize_text(answer_text)
    end

    def deserialize_blank_answer(answer_text)
      answer_text
    end

    private

    # @return [Boolean] True if the blank_id is recognized
    def blank_available?(blank_id)
      answers.any? { |answer| answer[:blank_id] == blank_id }
    end

    # something like: "question_5_1813d2a7223184cf43e19db6622df40b"
    def answer_blank_key(blank)
      [ question_key, Util.blank_id(blank) ].join('_')
    end
  end
end
