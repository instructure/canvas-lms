require_relative 'selective_release_homework_assignments_module'
require_relative 'selective_release_homework_discussions_module'
require_relative 'selective_release_homework_quizzes_module'

module SelectiveRelease
  module Homework
    class << self

      def initialize(course)
        SelectiveRelease::Homework::Assignments.initialize(course)
        SelectiveRelease::Homework::Discussions.initialize(course)
        SelectiveRelease::Homework::Quizzes.initialize(course)
      end
    end
  end
end