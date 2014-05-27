module CanvasQuizStatistics::Analyzers::Concerns
  # Helpers for calculating numbers of responses each answer has received.
  #
  # Only works for question types that have pre-defined answers, like
  # MultipleChoice, FIMB, etc.
  module HasAnswers
    Constants = CanvasQuizStatistics::Analyzers::Base::Constants

    protected

    # Override if you need more sophisticated answer metrics. Alternatively, you
    # can pass a block that will be run on each built answer so you can customize.
    #
    # Stock routine provides the following:
    #
    # {
    #   "id": "1234", // ID is always stringifed
    #   "text": "Answer text.",
    #   "correct": true // based on weight
    # }
    def parse_answers(source=@question_data[:answers], &formatter)
      return [] if source.blank?

      source.map do |answer|
        stats = build_answer(answer[:id], answer[:text], answer[:weight] == 100)
        yield answer, stats if block_given?
        stats
      end
    end

    # Loop over the responses and calculate how many responses each answer
    # has received.
    #
    # @param [Array<Hash>] answers
    # The answer set which contains the answers the responses may map to.
    # See #parse_answers for generating such a set.
    #
    # @param [Any...] args
    # Extra parameters you may need to pass on to your resolvers in
    # #locate_answer and #answer_present_but_unknown? to do the work.
    #
    # @warn
    # Has side-effects on @answers:
    #
    #   - the :responses key of each answer entry may be incremented
    #   - the set itself may be mutated by adding new answers to it (the
    #     aggregate "Other" and "Missing" answers)
    #
    # @return [NilClass]
    def calculate_responses(responses, answers, *args)
      responses.each do |response|
        answer = locate_answer(response, answers, *args)
        answer ||= begin
          if answer_present_but_unknown?(response, *args)
            generate_unknown_answer(answers)
          else
            generate_missing_answer(answers)
          end
        end

        answer[:responses] += 1
      end
    end

    # Search for a pre-defined answer in the given answer set based on the
    # student's response.
    #
    # Example implementation that attempts to locate the answer by id:
    #
    #   answers.detect { |a| a[:id] == "#{response[:answer_id]}" }
    #
    # @return [Hash|NilClass]
    def locate_answer(response, answers, *args)
      raise NotImplementedError
    end

    # If this question type supports "free-form" input where students can
    # provide a response that does not map to any answer the teacher pre-defines,
    # then these responses can be aggregated into an "unknown" answer instead of
    # considering them missing.
    #
    # @note
    # This will only be considered if the question was unable to locate a
    # pre-defined answer in #locate_answer.
    #
    # @return [Boolean]
    def answer_present_but_unknown?(response, *args)
      answer_present?(response)
    end

    private

    def build_answer(id, text, correct=false)
      {
        id: "#{id}",
        text: text.to_s,
        correct: correct,
        responses: 0
      }
    end

    def generate_unknown_answer(set)
      __generate_incorrect_answer(Constants::UnknownAnswerKey,
        Constants::UnknownAnswerText,
        set)
    end

    def generate_missing_answer(set)
      __generate_incorrect_answer(Constants::MissingAnswerKey,
        Constants::MissingAnswerText,
        set)
    end

    def __generate_incorrect_answer(id, text, answer_set)
      answer = answer_set.detect { |a| a[:id] == id }

      if answer.nil?
        answer = build_answer(id, text)
        answer_set << answer
      end

      answer
    end
  end
end