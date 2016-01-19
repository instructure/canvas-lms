require_relative '../spec_components/spec_components_assignment'
require_relative 'selective_release_wrappable'

module SelectiveRelease
  class Assignment < SpecComponents::Assignment
    include SelectiveReleaseWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: SelectiveRelease.the_course, title: "Assignment for #{self.assignees_list}")
    end
  end
end