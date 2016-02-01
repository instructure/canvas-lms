require_relative 'selective_release_homework_assignee_module'

module SelectiveRelease
  module SelectiveReleaseWrappable
    include HomeworkAssignee

    attr_reader :assignees

    def assignees_list
      self.assignees.to_sentence
    end

    def assign_overrides
      self.assignees.each { |assignee| assign_to(assignee) }
    end

    private

      def initialize_assignees(assignees)
        @assignees = Array(assignees)
        validate_self
      end

      def validate_self
        raise ArgumentError, 'Invalid homework assignee!' unless validate_assignees
      end

      def validate_assignees
        (SelectiveRelease::HomeworkAssignee::ASSIGNEES & self.assignees).empty?
      end

      def assign_to(assignee)
        users = SelectiveRelease::Users
        super(user: users.student(assignee)) if HomeworkAssignee::Student::ALL.include? assignee
        super(section: users.section(assignee)) if HomeworkAssignee::Section::ALL.include? assignee
        super(group: users.group(assignee)) if HomeworkAssignee::Group::ALL.include? assignee
      end
  end
end