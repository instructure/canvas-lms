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