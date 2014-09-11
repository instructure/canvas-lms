class Quizzes::QuizParticipant
  attr_accessor :user, :user_code, :access_code, :ip_address, :validation_token

  # An identity for a quiz participant, which can be an enrolled student,
  # an anonymous user, or a teacher.
  #
  # @param [User] user
  #   The person who wants to take the quiz.
  #
  # @param [String] user_code
  #   A unique code to use for identifying the participant in case the user is
  #   missing or is irrelevant (the case for preview mode). This code is usually
  #   found in the Rails session. See ApplicationController#temporary_user_code
  #   for more info.
  #
  # @param [String] access_code
  #   Access code required to take the quiz (if any.)
  #
  # @param [String] ip_address
  #   The IP address of the client's device that initiated the request.
  #
  # @param [String] token
  #   Validation token for the participant's existing quiz submission.
  #
  # @return [QuizParticipant]
  #   Participant instance ready for use by Quiz Services.
  def initialize(user, user_code, access_code=nil, ip_address=nil, token=nil)
    self.user = user
    self.user_code = user_code
    self.access_code = access_code
    self.ip_address = ip_address
    self.validation_token = token

    super()
  end

  # Is this a Canvas user (enrolled student, teacher, TA, etc.) or an anonymous
  # person?
  #
  # Note that this does not actually take the Quiz's public-participation status
  # into account, only the fact that the participant is authentic or not.
  def anonymous?
    self.user.nil? && self.user_code.present?
  end
end
