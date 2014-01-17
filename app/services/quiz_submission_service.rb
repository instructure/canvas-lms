class QuizSubmissionService
  include Api::V1::Helpers::QuizzesApiHelper
  include Api::V1::Helpers::QuizSubmissionsApiHelper

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
  # @throw ServiceError(403) if the student isn't allowed to take the quiz
  # @throw ServiceError(403) if the user is not logged in and the Quiz isn't public
  #
  # See #assert_takeability! for further errors that might be thrown.
  # See #assert_retriability! for further errors that might be thrown.
  #
  # @return [QuizSubmission]
  #   The (re)generated QS.
  def create(quiz)
    unless quiz.grants_right?(participant.user, :submit)
      reject! 403, 'you are not allowed to participate in this quiz'
    end

    assert_takeability! quiz, participant.access_code, participant.ip_address

    # Look up an existing QS, and if one exists, make sure it is retriable.
    assert_retriability! participant.find_quiz_submission(quiz.quiz_submissions, {
      :order => 'created_at'
    })

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
  # @throw ServiceError(403) if the user isn't privileged to update the Quiz
  #
  # @return [QuizSubmission]
  #   The newly created preview QS.
  def create_preview(quiz, session)
    unless quiz.grants_right?(participant.user, session, :update)
      reject! 403, 'you are not allowed to preview this quiz'
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
  # @throw ServiceError(403) if the participant can't take the quiz
  # @throw ServiceError(400) if the QS is already complete
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
      reject! 403, 'you are not allowed to complete this quiz submission'
    end

    # Participant must be able to take the quiz...
    assert_takeability! quiz, participant.access_code, participant.ip_address

    # And be the owner of the quiz submission:
    validate_token! quiz_submission, participant.validation_token

    # The QS must be completable:
    unless quiz_submission.untaken?
      reject! 400, 'quiz submission is already complete'
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
  # @throw ApiError(403) if the participant user isn't a teacher
  # @throw ApiError(400) if the attempt isn't valid, or isn't complete
  # @throw ApiError(400) if a question score is funny
  def update_scores(quiz_submission, attempt, scoring_data)
    unless quiz_submission.grants_right?(participant.user, :update_scores)
      reject! 403, 'you are not allowed to update scores for this quiz submission'
    end

    if !attempt
      reject! 400, 'invalid attempt'
    end

    version = quiz_submission.versions.get(attempt.to_i)

    if version.nil?
      reject! 400, 'invalid attempt'
    elsif !version.model.completed?
      reject! 400, 'quiz submission attempt must be complete'
    end

    # map the scoring data to the legacy format of QuizSubmission#update_scores
    legacy_params = {}.with_indifferent_access
    legacy_params[:submission_version_number] = attempt.to_i

    if scoring_data[:fudge_points].present?
      legacy_params[:fudge_points] = scoring_data[:fudge_points].to_f
    end

    if scoring_data[:questions].is_a?(Hash)
      scoring_data[:questions].each_pair do |question_id, question_data|
        question_id = question_id.to_i
        score, comment = question_data[:score], question_data[:comment]

        if score.present?
          legacy_params["question_score_#{question_id}".to_sym] = begin
            score.to_f
          rescue
            reject! 400, 'question score must be an unsigned decimal'
          end
        end

        # nil represents lack of change to a comment, '' means no comment
        unless comment.nil?
          legacy_params["question_comment_#{question_id}".to_sym] = comment.to_s
        end
      end
    end

    unless legacy_params.except(:submission_version_number).empty?
      quiz_submission.update_scores(legacy_params)
    end
  end

  protected

  # Abort the current service request with an error similar to an API error.
  #
  # See Api#reject! for usage.
  def reject!(status, cause)
    raise Api::V1::ApiError.new(status, cause)
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
  # @param [String] access_code
  #   The Access Code provided by the client.
  # @param [String] ip_address
  #   The IP address of the client.
  #
  # @throw ServiceError(400) if the Quiz is locked
  # @throw ServiceError(403) if the access code is invalid
  # @throw ServiceError(403) if the IP address isn't covered
  def assert_takeability!(quiz, access_code = nil, ip_address = nil)
    if quiz.locked?
      reject! 400, 'quiz is locked'
    end

    validate_access_code! quiz, access_code
    validate_ip_address! quiz, ip_address
  end

  # Verify the given QS is retriable.
  #
  # @throw ServiceError(409) if the QS is not new and can not be retried
  #
  # See QuizSubmission#retriable?
  def assert_retriability!(quiz_submission)
    if quiz_submission.present? && !quiz_submission.retriable?
      reject! 409, 'a quiz submission already exists'
    end
  end

  # Verify that the given access code matches the one set by the Quiz author.
  #
  # @param [Quiz] quiz
  #   The Quiz to test.
  # @param [String] access_code
  #   The user-supplied Access Code to validate.
  #
  # @throw ApiError(403) if the access code is invalid
  def validate_access_code!(quiz, access_code)
    if quiz.access_code.present? && quiz.access_code != access_code
      reject! 403, 'invalid access code'
    end
  end

  # Verify that the given IP address is allowed to access a Quiz.
  #
  # @param [Quiz] quiz
  #   The Quiz to test.
  # @param [String] ip_address
  #   IP address of the request originated from.
  #
  # @throw ApiError(403) if the IP address isn't covered
  def validate_ip_address!(quiz, ip_address)
    if quiz.ip_filter && !quiz.valid_ip?(ip_address)
      reject! 403, 'IP address denied'
    end
  end

  def validate_token!(quiz_submission, validation_token)
    unless quiz_submission.valid_token?(validation_token)
      reject! 403, 'invalid token'
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
  # @throw ServiceError(400) if attempt isn't a valid integer
  # @throw ServiceError(400) if attempt is invalid (ie, isn't the latest one)
  def ensure_latest_attempt!(quiz_submission, attempt)
    attempt = Integer(attempt) rescue nil

    if !attempt
      reject! 400, 'invalid attempt'
    elsif !quiz_submission.preview? && quiz_submission.attempt != attempt
      reject! 400, "attempt #{attempt} can not be modified"
    end
  end
end