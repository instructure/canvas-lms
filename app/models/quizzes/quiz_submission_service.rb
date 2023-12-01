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

class Quizzes::QuizSubmissionService
  attr_accessor :participant

  # @param [QuizParticipant] participant
  #   The person that wants to take the quiz. This could be:
  #
  #     - a student
  #     - a teacher/quiz author who wants to preview the quiz.
  #       Note that the participant's user_code must be set in this case.
  #     - an anonymous user taking a public course's quiz
  #
  def initialize(participant)
    self.participant = participant
    super()
  end

  # Create a QuizSubmission, or re-generate an existing one if viable.
  #
  # Semantically, creating a QS means taking a Quiz, and re-generating it means
  # re-trying it (doing another attempt.) See QuizSubmission#retriable? for
  # regeneration conditions.
  #
  # @param [Quiz] quiz
  #   The Quiz to take.
  #
  # @throw RequestError(403) if the student isn't allowed to take the quiz
  # @throw RequestError(403) if the user is not logged in and the Quiz isn't public
  #
  # See #assert_takeability! for further errors that might be thrown.
  # See #assert_retriability! for further errors that might be thrown.
  #
  # @return [QuizSubmission]
  #   The (re)generated QS.
  def create(quiz)
    unless quiz.grants_right?(participant.user, :submit)
      reject! "you are not allowed to participate in this quiz", 403
    end

    assert_takeability! quiz

    # Look up an existing QS, and if one exists, make sure it is retriable.
    assert_retriability! quiz.quiz_submissions.order(:created_at).for_participant(participant).first

    quiz.generate_submission_for_participant participant
  end

  # Create a "preview" Quiz Submission that doesn't count towards the quiz stats.
  #
  # Only quiz authors can launch the preview mode.
  #
  # @param [Quiz] quiz
  #   The Quiz to be previewed.
  #
  # @param [Hash] session
  #   The Rails session. Used for testing access permissions.
  #
  # @throw RequestError(403) if the user isn't privileged to update the Quiz
  #
  # @return [QuizSubmission]
  #   The newly created preview QS.
  def create_preview(quiz, session)
    unless quiz.grants_right?(participant.user, session, :update)
      reject! "you are not allowed to preview this quiz", 403
    end

    quiz.generate_submission(participant.user_code, true)
  end

  # Complete the quiz submission by marking it as complete and grading it. When
  # the quiz submission has been marked as complete, no further modifications
  # will be allowed.
  #
  # @param [QuizSubmission] quiz_submission
  #   The QS to complete.
  #
  # @param [Integer] attempt
  #   The QuizSubmission#attempt that is requested to be completed. This must
  #   match the quiz_submission's current attempt index.
  #
  # @throw RequestError(403) if the participant can't take the quiz
  # @throw RequestError(400) if the QS is already complete
  #
  # Further errors might be thrown from the following methods:
  #
  #   - #assert_takeability!
  #   - #assert_retriability!
  #   - #validate_token!
  #   - #ensure_latest_attempt!
  #
  # @return [QuizSubmission]
  #   The QS that was completed.
  def complete(quiz_submission, attempt)
    quiz = quiz_submission.quiz
    unless quiz.grants_right?(participant.user, :submit)
      reject! "you are not allowed to complete this quiz submission", 403
    end

    # Participant must be able to take the quiz...
    assert_takeability! quiz

    # And be the owner of the quiz submission:
    validate_token! quiz_submission, participant.validation_token

    # The QS must be completable:
    unless quiz_submission.untaken?
      reject! "quiz submission is already complete", 400
    end

    # And we need a valid attempt index to work with.
    ensure_latest_attempt! quiz_submission, attempt

    quiz_submission.complete!
  end

  # Modify question scores and comments for a student's quiz submission.
  #
  # @param [Hash] scoring_data
  #   So this is the set that contains the modifications you want to apply.
  #   The format is well-documented in the QuizSubmissionsApi#update endpoint,
  #   so check it out there.
  #
  # @option [Integer] attempt
  #   The attempt the modifications are for. This needs to map to a valid and
  #   _complete_ quiz submission attempt.
  #
  # @option [Float] scoring_data.fudge_points
  #   Amount of points to fudge the totalscore by.
  #
  # @option [Hash] scoring_data.questions
  #   Question scores and comments. The key is the question id.
  #
  # @option [Float] scoring_data.questions.score
  #   Question score. Nil, or lack of, represents no change.
  #
  # @option [String] scoring_data.questions.comment
  #   Question/answer comment. Nil, or lack of, represents no change. Empty
  #   string means remove any previous comments.
  #
  # @return [nil] nothing of significance
  #
  # @throw RequestError(403) if the participant user isn't a teacher
  # @throw RequestError(400) if the attempt isn't valid, or isn't complete
  # @throw RequestError(400) if a question score is funny
  def update_scores(quiz_submission, attempt, scoring_data)
    unless quiz_submission.grants_right?(participant.user, :update_scores)
      reject! "you are not allowed to update scores for this quiz submission", 403
    end

    unless attempt
      reject! "invalid attempt", 400
    end

    version = quiz_submission.versions.get(attempt.to_i)

    if version.nil?
      reject! "invalid attempt", 400
    elsif !version.model.completed?
      reject! "quiz submission attempt must be complete", 400
    end

    # map the scoring data to the legacy format of QuizSubmission#update_scores
    legacy_params = {}.with_indifferent_access
    legacy_params[:submission_version_number] = attempt.to_i

    if scoring_data[:fudge_points].present?
      legacy_params[:fudge_points] = scoring_data[:fudge_points].to_f
    end

    if scoring_data[:questions].is_a?(Hash) || scoring_data[:questions].is_a?(ActionController::Parameters)
      scoring_data[:questions].each_pair do |question_id, question_data|
        question_id = question_id.to_i
        score, comment = question_data[:score], question_data[:comment]

        if score.present?
          legacy_params[:"question_score_#{question_id}"] = begin
            score.to_f
          rescue
            reject! "question score must be an unsigned decimal", 400
          end
        end

        # nil represents lack of change to a comment, '' means no comment
        unless comment.nil?
          legacy_params[:"question_comment_#{question_id}"] = comment.to_s
        end
      end
    end

    unless legacy_params.except(:submission_version_number).empty?
      quiz_submission.update_scores(legacy_params)
    end
  end

  # Provide an answer to a question, or flag it, while taking a quiz. A snapshot
  # of the QS will be made with the new answer state.
  #
  # @param [Hash] question_record
  #   The "answer record" for the question in the QS's submission_data. This
  #   can be obtained using the QuizQuestion::AnswerSerializers for a given QQ.
  #
  # @param [QuizSubmission] quiz_submission
  #   The QS we're manipulating (answering/flagging.)
  #
  # @param [Integer] attempt
  #   The attempt index this answer/modification applies to. This must match
  #   the quiz_submission's current attempt index.
  #
  # @throw RequestError(403) if the participant can't update the QS (ie, not the owner)
  # @throw RequestError(400) if the QS is complete or overdue
  #
  # Further errors might be thrown from the following methods:
  #
  #   - #assert_takeability!
  #   - #assert_retriability!
  #   - #validate_token!
  #   - #ensure_latest_attempt!
  #
  # @return [Hash] the recently-adjusted submission_data set
  def update_question(question_record, quiz_submission, attempt, snapshot = true)
    unless quiz_submission.grants_right?(participant.user, :update)
      reject! "you are not allowed to update questions for this quiz submission", 403
    end

    if quiz_submission.completed?
      reject! "quiz submission is already complete", 400
    elsif quiz_submission.overdue?
      reject! "quiz submission is overdue", 400
    end

    assert_takeability! quiz_submission.quiz

    validate_token! quiz_submission, participant.validation_token

    ensure_latest_attempt! quiz_submission, attempt

    quiz_submission.backup_submission_data question_record.merge({
                                                                   validation_token: participant.validation_token,
                                                                   cnt: snapshot ? 5 : 1 # force generation of snapshot
                                                                 })
  end

  protected

  # Abort the current service request with an error similar to an API error.
  #
  # See Api#reject! for usage.
  def reject!(cause, status)
    raise RequestError.new(cause, status)
  end

  # Verify that none of the following Quiz restrictions are preventing the Quiz
  # from being taken by a client:
  #
  #   - the Quiz being locked
  #   - the Quiz access code
  #   - the Quiz active IP filter
  #
  # @param [Quiz] quiz
  #   The Quiz we're attempting to take.
  #
  # @param [QuizParticipant] participant
  #   The person trying to take the quiz.
  #
  # @param [String] participant.access_code
  #   The Access Code provided by the participant.
  #
  # @param [String] participant.ip_address
  #   The IP address of the participant.
  #
  # @throw RequestError(400) if the Quiz is locked
  # @throw RequestError(501) if the Quiz has the "can't go back" flag on
  # @throw RequestError(403) if the access code is invalid
  # @throw RequestError(403) if the IP address isn't covered
  def assert_takeability!(quiz, participant = self.participant)
    # [Transient:CNVS-10224] - support for CGB-OQAAT quizzes
    if quiz.cant_go_back
      reject! "that type of quizzes is not supported yet", 501
    end

    can_take = Quizzes::QuizEligibility.new(course: quiz.context,
                                            quiz:,
                                            user: participant.user,
                                            remote_ip: participant.ip_address,
                                            access_code: participant.access_code)

    unless can_take.eligible?
      reason = can_take.declined_reason_renders
      case reason
      when :access_code
        reject! "invalid access code", 403
      when :invalid_ip
        reject! "IP address denied", 403
      end
      reject! "quiz is locked", 400
    end
  end

  # Verify the given QS is retriable.
  #
  # @throw RequestError(409) if the QS is not new and can not be retried
  #
  # See QuizSubmission#retriable?
  def assert_retriability!(quiz_submission)
    if quiz_submission.present? && !quiz_submission.retriable?
      reject! "a quiz submission already exists", 409
    end
  end

  def validate_token!(quiz_submission, validation_token)
    unless quiz_submission.valid_token?(validation_token)
      reject! "invalid token", 403
    end
  end

  # Ensure that the QS attempt index is specified and is the latest one, unless
  # it's a preview QS.
  #
  # The reason we require an attempt to be explicitly specified and that
  # it must match the latest one is to avoid cases where the student leaves
  # an open session for an earlier attempt which might try to auto-submit
  # or backup answers, and those shouldn't overwrite the latest attempt's
  # data.
  #
  # @param [QuizSubmission] quiz_submission
  # @param [Integer|String] attempt
  #   The attempt to validate.
  #
  # @throw RequestError(400) if attempt isn't a valid integer
  # @throw RequestError(400) if attempt is invalid (ie, isn't the latest one)
  def ensure_latest_attempt!(quiz_submission, attempt)
    attempt = Integer(attempt) rescue nil

    if !attempt
      reject! "invalid attempt", 400
    elsif !quiz_submission.preview? && quiz_submission.attempt != attempt
      reject! "attempt #{attempt} can not be modified", 400
    end
  end
end
