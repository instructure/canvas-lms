require_relative '../spec_components/spec_components_quiz'
require_relative 'da_wrappable'

module DifferentiatedAssignments
  class Quiz < SpecComponents::Quiz
    include DifferentiatedAssignmentsWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: DifferentiatedAssignments.the_course, title: "Quiz for #{self.assignees_list}")
    end
  end
end
