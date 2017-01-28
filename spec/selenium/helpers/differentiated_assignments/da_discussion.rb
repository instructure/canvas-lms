require_relative '../spec_components/spec_components_discussion'
require_relative 'da_wrappable'

module DifferentiatedAssignments
  class Discussion < SpecComponents::Discussion
    include DifferentiatedAssignmentsWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: DifferentiatedAssignments.the_course, title: "Discussion for #{self.assignees_list}")
    end
  end
end
