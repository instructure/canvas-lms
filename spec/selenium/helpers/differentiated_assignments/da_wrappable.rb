require_relative 'da_homework_assignee_module'

module DifferentiatedAssignments
  module DifferentiatedAssignmentsWrappable
    include HomeworkAssignee

    attr_reader :assignees

    # Method returns a sorted English arrangement of the assignees array.
    # Example: Given the assignees array ['Section A', 'Section B'], the method
    #          will return 'Sections A and B'
    # Example: Given the assignees array ['Section A', 'Student 1'], the method
    #          will return 'Section A and Student 1'
    # Example: Given ['Section A', 'Section B', 'Section C'], returns 'Sections A, B, and C'
    # Example: Given ['Section A', 'Section B', 'Section C', 'Student 1', 'Student 4'],
    #          returns 'Sections A, B, and C, and Students 1 and 4'
    def assignees_list
      organized_assignees = []

      HomeworkAssignee::ASSIGNEE_TYPES.each do |type|
        types_list = organize_by_type(type)
        organized_assignees << types_list if types_list.size > 0
      end

      organized_assignees.sort!
      organized_assignees.to_sentence
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
        (DifferentiatedAssignments::HomeworkAssignee::ASSIGNEES & self.assignees).empty?
      end

      def assign_to(assignee)
        users = DifferentiatedAssignments::Users
        super(user: users.student(assignee)) if HomeworkAssignee::Student::ALL.include? assignee
        super(section: users.section(assignee)) if HomeworkAssignee::Section::ALL.include? assignee
        super(group: users.group(assignee)) if HomeworkAssignee::Group::ALL.include? assignee
      end

      def organize_by_type(type)
        grouped_type = assignees_by_type(type)

        if grouped_type.size > 1
          # turn into an array of the specific type assignees, e.g. ["1", "2", "3"]
          grouped_type_list = remove_word_from_array_items(grouped_type, type)

          # pluralize the type and make a list of the specific type
          "#{type}s #{grouped_type_list.to_sentence}"
        else
          grouped_type.to_sentence
        end
      end

      def remove_word_from_array_items(an_array, word)
        an_array.map { |item| item.sub(word, '').strip }
      end

      def assignees_by_type(type)
        self.assignees.select { |a| a.include? type }
                      .sort
      end
  end
end
