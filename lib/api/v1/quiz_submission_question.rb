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
  include Api::V1::QuizQuestion

  INCLUDABLES = %w[ quiz_question ]

  # @param [Array<QuizQuestion>] quiz_questions
  # @param [Hash] submission_data
  # @param [Hash] meta
  # @param [Array<String>] meta[:includes]
  # @param [User] meta[:user]
  # @param [Hash] meta[:session]
  # @param [Boolean] meta[:censored] if answer correctness should be censored out
  def quiz_submission_questions_json(quiz_questions, quiz_submission, meta = {})
    meta[:censored] ||= true
    quiz_questions = [ quiz_questions ] unless quiz_questions.kind_of?(Array)
    includes = (meta[:includes] || []) & INCLUDABLES

    data = {}
    data[:quiz_submission_questions] = quiz_questions.map do |qq|
      quiz_submission_question_json(qq, quiz_submission, meta)
    end

    if includes.include?('quiz_question')
      data[:quiz_questions] = questions_json(quiz_questions,
                                             meta[:user],
                                             meta[:session],
                                             nil, [],
                                             meta[:censored],
                                             quiz_submission.quiz_data,
                                             shuffle_answers: meta[:shuffle_answers])
    end

    unless includes.empty?
      data[:meta] = { primaryCollection: 'quiz_submission_questions' }
    end

    data
  end

  # A renderable version of a QuizQuestion's "answer" record in a submission's
  # answer set. The answer construct contains three pieces of data:
  #
  #   - the question's id
  #   - its "flagged" status
  #   - a representation of its answer which depends on the type of question it
  #     is. See QuizQuestion::AnswerSerializers for possible answer formats.
  #   - if the answer is correct when applicable.
  #
  # @param [QuizQuestion] qq
  #   A question of a Quiz.
  #
  # @param [QuizSubmission] qs
  #   The QuizSubmission from which the question's answer record
  #   will be looked up and serialized.
  # @param [Hash] meta
  #   Conditional option settings, including :quiz_data, :censored, :includes, :user, and :session parameters.
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
  def quiz_submission_question_json(qq, qs, meta={})
    answer_serializer = Quizzes::QuizQuestion::AnswerSerializers.serializer_for(qq)
    meta[:includes] ||= []
    data = question_json(qq,
      meta[:user],
      meta[:session],
      nil,
      meta[:includes],
      meta[:censored],
      qs[:quiz_data],
      shuffle_answers: meta[:shuffle_answers]
    )

    if qs.submission_data.is_a? Hash #ungraded
      data[:flagged] = to_boolean(qs.submission_data["question_#{qq.id}_marked"])
      data[:answer] = answer_serializer.deserialize(qs.submission_data, true)
    else
      question_data = qs.submission_data.select {|h| h[:question_id] == qq.id}
      return data if question_data.empty?
      data[:flagged] = false
      data[:correct] = question_data.first[:correct]
    end
    data
  end


  private
  def to_boolean(v)
    Canvas::Plugin.value_to_boolean(v)
  end
end
