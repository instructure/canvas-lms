module Quizzes::QuizQuestion::AnswerSerializers
  class Quizzes::QuizQuestion::AnswerSerializers::SerializedAnswer

    # @property [Hash] answer
    #
    # The output of the serializer which is compatible for merging with
    # QuizSubmission#submission_data.
    attr_accessor :answer

    # @property [String|NilClass] error
    #
    # Will contain a descriptive error message if the serialization fails, nil
    # otherwise.
    attr_accessor :error

    def initialize
      self.answer = {}.with_indifferent_access
    end

    # @return [Boolean] Whether the answer has been serialized successfully.
    def valid?
      error.blank?
    end

    def reject(reason, *args)
      self.error = reason.to_s

      if reason.is_a?(Symbol) && ERROR_CODES.has_key?(reason)
        actual_reason = ERROR_CODES[reason]
        actual_reason = actual_reason.call(*args) if actual_reason.is_a?(Proc)

        self.error = actual_reason
      end

      self
    end

    private

    ERROR_CODES = {
      invalid_type: lambda { |param_name, expected_type|
        '%s must be of type %s' % [ param_name, expected_type.to_s ]
      },
      unknown_answer: lambda { |id| "Unknown answer '#{id}'" },
      unknown_match: lambda { |id| "Unknown match '#{id}'" },
      unknown_blank: lambda { |id| "Unknown blank '#{id}'" },
      text_too_long: 'Text is too long.'
    }
  end
end
