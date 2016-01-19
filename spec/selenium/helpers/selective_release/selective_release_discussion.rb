require_relative '../spec_components/spec_components_discussion'
require_relative 'selective_release_wrappable'

module SelectiveRelease
  class Discussion < SpecComponents::Discussion
    include SelectiveReleaseWrappable

    def initialize(assignees)
      initialize_assignees(assignees)
      super(course: SelectiveRelease.the_course, title: "Discussion for #{self.assignees_list}")
    end
  end
end