require_relative '../spec_components/spec_components_assignment'
require_relative 'selective_release_wrappable'

module SelectiveRelease
  class Assignment < SpecComponents::Assignment
    include SelectiveReleaseWrappable

    def initialize(course, assignees)
      initialize_assignees(assignees)
      super(course, "Assignment for #{self.assignees_list}")
    end
  end
end