# encoding: UTF-8

class Quizzes::QuizSubmissionAttempt
  attr_reader :number, :versions

  def initialize(attrs = {})
    @number = attrs[:number]
    @versions = attrs[:versions]
  end
end
