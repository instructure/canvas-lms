# frozen_string_literal: true

class Quizzes::QuizSubmissionAttempt
  attr_reader :number, :versions

  def initialize(attrs = {})
    @number = attrs[:number]
    @versions = attrs[:versions]
  end
end
