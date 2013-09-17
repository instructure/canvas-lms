class QuizRegrader::AttemptVersion

  attr_reader :version, :question_regrades

  def initialize(hash)
    @version           = hash.fetch(:version)
    @question_regrades = hash.fetch(:question_regrades)
  end

  def regrade!
    version.model = QuizRegrader::Submission.new(
      :submission        => version.model,
      :question_regrades => question_regrades).rescored_submission
    version.save!
  end

end