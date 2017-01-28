require_relative 'da_homework_assignments_module'
require_relative 'da_homework_discussions_module'
require_relative 'da_homework_quizzes_module'

module DifferentiatedAssignments
  module Homework
    class << self

      def initialize
        DifferentiatedAssignments::Homework::Assignments.initialize
        DifferentiatedAssignments::Homework::Discussions.initialize
        DifferentiatedAssignments::Homework::Quizzes.initialize
      end
    end
  end
end
