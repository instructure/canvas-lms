require_relative '../spec_components/spec_components_quiz'
require_relative 'selective_release_wrappable'

module SelectiveRelease
  class Quiz < SpecComponents::Quiz
    include SelectiveReleaseWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: SelectiveRelease.the_course, title: "Quiz for #{self.assignees_list}")
    end
  end
end