# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
