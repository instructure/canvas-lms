class Quizzes::QuizStatistics::Report
  extend Forwardable

  attr_reader :quiz_statistics

  def_delegators :quiz_statistics,
    :quiz,
    :includes_all_versions?,
    :anonymous?,
    :start_progress,
    :update_progress,
    :t

  def initialize(quiz_statistics)
    @quiz_statistics = quiz_statistics
  end

  def generatable?
    true
  end

  def readable_type
    self.class.name.demodulize.underscore
  end
end