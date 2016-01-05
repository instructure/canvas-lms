module SelectiveRelease
  module HomeworkAssignee
    module Student
      FIRST_STUDENT  = 'First Student'.freeze
      SECOND_STUDENT = 'Second Student'.freeze
      THIRD_STUDENT  = 'Third Student'.freeze
      FOURTH_STUDENT = 'Fourth Student'.freeze
      ALL            = Student.constants.map { |c| Student.const_get(c) }
    end

    module Section
      SECTION_A = 'Section A'.freeze
      SECTION_B = 'Section B'.freeze
      SECTION_C = 'Section C'.freeze
      ALL       = Section.constants.map { |c| Section.const_get(c) }
    end

    module Group
      GROUP_X = 'Student Group X'.freeze
      GROUP_Y = 'Student Group Y'.freeze
      GROUP_Z = 'Student Group Z'.freeze
      ALL     = Group.constants.map { |c| Group.const_get(c) }
    end

    EVERYONE  = 'Everyone'.freeze
    ALL       = HomeworkAssignee.constants.map { |c| HomeworkAssignee.const_get(c) }
    ASSIGNEES = [
      HomeworkAssignee::Student::ALL,
      HomeworkAssignee::Section::ALL,
      HomeworkAssignee::Group::ALL,
      HomeworkAssignee::ALL
    ].freeze
  end
end