module CanvasQuizStatistics
  require 'canvas_quiz_statistics/version'
  require 'canvas_quiz_statistics/util'
  require 'canvas_quiz_statistics/analyzers'

  def self.can_analyze?(question_data)
    Analyzers[question_data[:question_type]] != Analyzers::Base
  end

  def self.analyze(question_data, responses)
    analyzer = Analyzers[question_data[:question_type]].new(question_data)
    analyzer.run(responses)
  end
end
