require_relative '../spec_components/spec_components_course_module'

module SelectiveRelease
  module CourseModules
    class << self
      attr_reader :course, :first_module, :second_module, :third_module, :fourth_module

      def initialize(course)
        @course        = course
        @first_module  = create_course_module('Module 0')
        @second_module = create_course_module('Module 1') # TODO: Add prerequisite complete Module 0 first
        @third_module  = create_course_module('Module 2')
        @fourth_module = create_course_module('Module 3')
        add_assignments_to_modules
      end

      private

        def create_course_module(module_name)
          SpecComponents::CourseModule.new(self.course, module_name)
        end

        def add_assignments_to_modules
          self.first_module.add_assignment(SelectiveRelease::Homework::Assignments.assignment_for_section_a)
          self.first_module.add_assignment(SelectiveRelease::Homework::Assignments.assignment_for_section_b)
          self.first_module.add_assignment(SelectiveRelease::Homework::Assignments.assignment_for_first_student)

          self.second_module.add_quiz(SelectiveRelease::Homework::Quizzes.quiz_for_section_a)
          self.second_module.add_quiz(SelectiveRelease::Homework::Quizzes.quiz_for_section_b)
          self.second_module.add_quiz(SelectiveRelease::Homework::Quizzes.quiz_for_second_and_third_students)

          self.third_module.add_discussion(SelectiveRelease::Homework::Discussions.discussion_for_section_a)
          self.third_module.add_discussion(SelectiveRelease::Homework::Discussions.discussion_for_section_b)
          self.third_module.add_discussion(SelectiveRelease::Homework::Discussions.discussion_for_first_student)

          self.fourth_module.add_assignment(SelectiveRelease::Homework::Assignments.assignment_for_section_c)
        end
    end
  end
end