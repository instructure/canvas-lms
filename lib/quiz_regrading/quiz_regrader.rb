class QuizRegrader

  attr_reader :quiz, :quiz_version_number

  def initialize(options)
    @quiz_version_number = options.fetch(:version_number, nil)
    @quiz                = find_quiz_version(options.fetch(:quiz))
    @submissions         = options.fetch(:submissions, nil)
  end

  def regrade!
    regrade = quiz.current_regrade
    return true unless regrade && question_regrades.size > 0

    QuizRegradeRun.perform(regrade) do
      submissions.each do |submission|
        QuizRegrader::Submission.new(
          :submission        => submission,
          :question_regrades => question_regrades).regrade!
      end
    end
  end

  def self.regrade!(options)
    QuizRegrader.new(options).regrade!
  end

  def submissions
    # Using a class level scope here because if a restored "model" from a quiz
    # version is passed (e.g. during the grade_submission method on quiz
    # submissions), the association will always be empty.
    @submissions ||= QuizSubmission.where(quiz_id: quiz.id).select(&:completed?)
  end

  private

  def find_quiz_version(quiz)
    return quiz unless quiz_version_number.present?
    Version.where(
      versionable_type: "Quiz",
      versionable_id: quiz.id,
      number: quiz_version_number).first.model
  end

  # quiz question regrades keyed by question id
  def question_regrades
    @questions ||= @quiz.current_quiz_question_regrades.each_with_object({}) do |qr, hash|
      hash[qr.quiz_question_id] = qr
    end
  end
end
