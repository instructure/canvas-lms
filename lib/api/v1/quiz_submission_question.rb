#
# Copyright (C) 2012 Instructure, Inc.
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
#

module Api::V1::QuizSubmissionQuestion

  def quiz_submission_questions_json(quiz_questions, submission_data)
    {
      quiz_submission_questions: quiz_questions.map do |qq|
        quiz_submission_question_json(qq, submission_data)
      end
    }
  end

  # A renderable version of a QuizQuestion's "answer" record in a submission's
  # answer set. The answer construct contains three pieces of data:
  #
  #   - the question's id
  #   - its "flagged" status
  #   - a representation of its answer which depends on the type of question it
  #     is. See QuizQuestion::AnswerSerializers for possible answer formats.
  #
  # @param [QuizQuestion] qq
  #   A question of a Quiz.
  #
  # @param [Hash] submission_data
  #   The QuizSubmission#submission_data in which the question's answer record
  #   will be looked up and serialized.
  #
  # @return [Hash]
  #   The question's answer record. See example for what it contains.
  #
  # @example output for a multiple-choice quiz question
  #   {
  #     id: 5,
  #     flagged: true,
  #     answer: 123
  #   }
  def quiz_submission_question_json(qq, submission_data)
    answer_serializer = QuizQuestion::AnswerSerializers.serializer_for(qq)

    data = {}
    data[:id] = qq.id
    data[:flagged] = to_boolean(submission_data["question_#{qq.id}_marked"])
    data[:answer] = answer_serializer.deserialize(submission_data)
    data
  end

  private

  def to_boolean(v)
    Canvas::Plugin.value_to_boolean(v)
  end
end
