class Quizzes::QuizStatisticsService
  attr_accessor :quiz

  def initialize(quiz)
    self.quiz = quiz
  end

  # @param [Boolean] all_versions
  #   Describes if you want the statistics to represent all the submissions versions.
  #
  # @return [QuizStatisticsSerializer::Input]
  #   An object ready for API serialization containing (persisted) versions of
  #   the *latest* Student and Item analysis for the quiz.
  def generate_aggregate_statistics(all_versions)
    if Quizzes::QuizStatistics.large_quiz?(quiz)
      reject! 'operation not available for large quizzes', 400
    end

    Quizzes::QuizStatisticsSerializer::Input.new(quiz, *[
      quiz.current_statistics_for('student_analysis', {
        includes_all_versions: all_versions
      }),
      quiz.current_statistics_for('item_analysis')
    ])
  end

  protected

  # Abort the current service request with an error similar to an API error.
  #
  # See Api#reject! for usage.
  def reject!(cause, status)
    raise RequestError.new(cause, status)
  end
end