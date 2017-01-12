#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

module Api::V1::QuizSubmission
  include Api::V1::Json
  include Api::V1::Submission
  include Api::V1::Quiz
  include Api::V1::User

  QUIZ_SUBMISSION_JSON_FIELDS = %w[
    id
    user_id
    submission_id
    quiz_id
    quiz_points_possible
    quiz_version
    attempt
    extra_attempts
    extra_time
    manually_unlocked
    started_at
    finished_at
    end_at
    fudge_points
    kept_score
    score
    score_before_regrade
    has_seen_results
    validation_token
    workflow_state
  ].freeze

  QUIZ_SUBMISSION_JSON_FIELD_METHODS = %w[
    time_spent
    attempts_left
    overdue_and_needs_submission
    excused?
  ].freeze

  def quiz_submission_json(qs, quiz, user, session, context = nil)
    context ||= quiz.context

    hash = api_json(qs, user, session, {
      only: QUIZ_SUBMISSION_JSON_FIELDS,
      methods: QUIZ_SUBMISSION_JSON_FIELD_METHODS.dup
    })

    hash.merge!({
      html_url: course_quiz_quiz_submission_url(context, quiz, qs)
    })

    hash.merge!({
      result_url: course_quiz_history_url(context, quiz, quiz_submission_id: qs.id, version: qs.version_number)
    }) if qs.completed? || qs.needs_grading?

    hash
  end

  # Render a set of Quiz Submission objects as JSON-API.
  #
  # @param [QuizSubmission|Array<QuizSubmission>] quiz_submissions
  #   The resource(s) to render.
  #
  # @param [Array<String>] includes
  #   Associations to include in the output for each Quiz Submission.
  #   Allowed associations are: "user", "quiz", and "submission"
  #
  # @return [Hash]
  #   A JSON-API complying construct representing the quiz submissions, and
  #   any associations requested.
  def quiz_submissions_json(quiz_submissions, quiz, user, session, context = nil, includes = [])
    hash = {}
    hash[:quiz_submissions] = [ quiz_submissions ].flatten.map do |qs|
      quiz_submission_json(qs, quiz, user, session, context)
    end

    if includes.include?('submission')
      with_submissions = quiz_submissions.select { |qs| !!qs.submission }

      hash[:submissions] = with_submissions.map do |qs|
        submission_json(qs.submission, quiz.assignment, user, session, context)
      end
    end

    if includes.include?('quiz')
      hash[:quizzes] = [
        quiz_json(quiz, context, user, session)
      ]
    end

    if includes.include?('user')
      hash[:users] = quiz_submissions.map do |qs|
        user_json(qs.user, user, session, ['avatar_url'], context, nil)
      end
    end

    unless includes.empty?
      hash[:meta] = {
        primaryCollection: 'quiz_submissions'
      }
    end

    hash
  end

  def quiz_submission_zip(quiz)
    latest_submission = quiz.quiz_submissions.map { |s| s.finished_at }.compact.max
    submission_zip(quiz, latest_submission)
  end
end

