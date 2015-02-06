module Quizzes::QuizQuestion::AnswerSerializers
  class Matching < Quizzes::QuizQuestion::AnswerSerializers::AnswerSerializer
    # Accept a set of pairings between answer and match IDs.
    #
    # Serialization request is rejected if:
    #
    #   - the answer isn't an Array
    #   - an answer entry (pairing) isn't a Hash
    #   - an answer entry is missing either id
    #   - either answer_id or match_id isn't a valid number
    #   - either answer_id or match_id can't be resolved
    #
    # @example input
    #   [{
    #     answer_id: 123,
    #     match_id: 456
    #   }]
    #
    # @example output
    #   {
    #     question_5_answer_123: "456"
    #   }
    def serialize(pairings)
      rc = SerializedAnswer.new

      unless pairings.is_a?(Array)
        return rc.reject :invalid_type, 'answer', Array
      end

      pairings.each_with_index do |entry, index|
        answer_id, match_id = nil, nil

        unless entry.is_a?(Hash)
          return rc.reject :invalid_type, "answer[#{index}]", Hash
        end

        entry = entry.with_indifferent_access

        %w[ answer_id match_id ].each do |required_param|
          unless entry.has_key?(required_param)
            return rc.reject 'Matching pair is missing parameter "%s"' % [
              required_param
            ]
          end
        end

        answer_id = Util.to_integer(entry[:answer_id])

        if answer_id.nil?
          return rc.reject :invalid_type, 'answer_id', Integer
        end

        unless answer_available? answer_id
          return rc.reject :unknown_answer, answer_id
        end

        match_id = Util.to_integer(entry[:match_id])

        if match_id.nil?
          return rc.reject :invalid_type, 'match_id', Integer
        end

        unless match_available? match_id
          return rc.reject :unknown_match, match_id
        end

        rc.answer[build_answer_key(answer_id)] = match_id.to_s
      end

      rc
    end

    # @return [Array<Hash{String => String}>]
    #   Pairs of answer-match records.
    #
    # @example output for answer #1 matched to match #2:
    #   [{ "answer_id": "1", "match_id": "2" }]
    #
    # @example output for answer #1 not matched to anything:
    #   [{ "answer_id": "1", "match_id": null }]
    def deserialize(submission_data, full=false)
      answers.each_with_object([]) do |answer_record, out|
        answer_id = answer_record[:id]
        answer_key = build_answer_key(answer_id)

        match_id = submission_data[answer_key] # this is always a string
        has_match = match_id.present?

        if has_match || full
          out << {
            answer_id: answer_id.to_s,
            match_id: has_match ? match_id : nil
          }.with_indifferent_access
        end
      end
    end

    private

    def build_answer_key(answer_id)
      [ question_key, 'answer', answer_id ].join('_')
    end

    def match_ids
      @match_ids ||= frozen_question_data[:matches].map do |match_record|
        match_record[:match_id].to_i
      end
    end

    def match_available?(match_id)
      match_ids.include?(match_id)
    end
  end
end
