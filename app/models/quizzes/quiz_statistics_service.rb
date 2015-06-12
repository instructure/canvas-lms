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

    Quizzes::QuizStatisticsSerializer::Input.new(quiz, *[
      quiz.current_statistics_for('student_analysis', {
        includes_all_versions: all_versions
      }),
      quiz.current_statistics_for('item_analysis')
    ])
  end
end