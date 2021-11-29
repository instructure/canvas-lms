# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

      if reason.is_a?(Symbol) && ERROR_CODES.key?(reason)
        actual_reason = ERROR_CODES[reason]
        actual_reason = actual_reason.call(*args) if actual_reason.is_a?(Proc)

        self.error = actual_reason
      end

      self
    end

    ERROR_CODES = {
      invalid_type: lambda do |param_name, expected_type|
        "%s must be of type %s" % [param_name, expected_type.to_s]
      end,
      unknown_answer: ->(id) { "Unknown answer '#{id}'" },
      unknown_match: ->(id) { "Unknown match '#{id}'" },
      unknown_blank: ->(id) { "Unknown blank '#{id}'" },
      text_too_long: "Text is too long."
    }.freeze
    private_constant :ERROR_CODES
  end
end
