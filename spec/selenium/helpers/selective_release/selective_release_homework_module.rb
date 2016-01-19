require_relative 'selective_release_homework_assignments_module'
require_relative 'selective_release_homework_discussions_module'
require_relative 'selective_release_homework_quizzes_module'

module SelectiveRelease
  module Homework
    class << self

      def initialize
        SelectiveRelease::Homework::Assignments.initialize
        SelectiveRelease::Homework::Discussions.initialize
        SelectiveRelease::Homework::Quizzes.initialize
      end
    end
  end
end