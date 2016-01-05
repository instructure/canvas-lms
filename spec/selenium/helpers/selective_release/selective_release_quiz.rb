require_relative '../spec_components/spec_components_quiz'
require_relative 'selective_release_wrappable'

module SelectiveRelease
  class Quiz < SpecComponents::Quiz
    include SelectiveReleaseWrappable

    def initialize(course, assignees)
      initialize_assignees(assignees)
      super(course, "Quiz for #{self.assignees_list}")
    end
  end
end