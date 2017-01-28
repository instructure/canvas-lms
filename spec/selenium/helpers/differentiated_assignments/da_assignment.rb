require_relative '../spec_components/spec_components_assignment'
require_relative 'da_wrappable'

module DifferentiatedAssignments
  class Assignment < SpecComponents::Assignment
    include DifferentiatedAssignmentsWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: DifferentiatedAssignments.the_course, title: "Assignment for #{self.assignees_list}")
    end
  end
end
