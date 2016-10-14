module Quizzes::QuizQuestion::AnswerSerializers
  class Error < StandardError
  end

  class << self
    # Get an instance of an AnswerSerializer appropriate for the given question.
    #
    # @param [QuizQuestion] question
    #   The question to locate the serializer for.
    #
    # @return [AnswerSerializer]
    #   The serializer.
    #
    # @throw NameError if no serializer was found for the given question
    def serializer_for(question)
      question_type = question.respond_to?(:data) ?
        question.data[:question_type] :
        question[:question_type]

      klass = question_type.gsub(/_question$/, '').demodulize.camelize


      begin
        # raise name_error because `::Error` is in the namespace, but is not a valid answer type
        raise NameError if klass == 'Error'
        "Quizzes::QuizQuestion::AnswerSerializers::#{klass}".constantize.new(question)
      rescue NameError
        Quizzes::QuizQuestion::AnswerSerializers::Unknown.new(question)
      end
    end
  end
end
