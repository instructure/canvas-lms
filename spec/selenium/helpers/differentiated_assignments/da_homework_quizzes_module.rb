require_relative 'da_quiz'

module DifferentiatedAssignments
  module Homework
    module Quizzes
      class << self
        attr_reader :quiz_for_everyone, :quiz_for_section_a, :quiz_for_section_b, :quiz_for_section_c,
          :quiz_for_sections_a_and_b, :quiz_for_first_student, :quiz_for_second_and_third_students

        def initialize
          @quiz_for_everyone                  = create_quiz_for(HomeworkAssignee::EVERYONE)
          @quiz_for_section_a                 = create_quiz_for(HomeworkAssignee::Section::SECTION_A)
          @quiz_for_section_b                 = create_quiz_for(HomeworkAssignee::Section::SECTION_B)
          @quiz_for_sections_a_and_b          = create_quiz_for([ HomeworkAssignee::Section::SECTION_A, HomeworkAssignee::Section::SECTION_B ])
          @quiz_for_section_c                 = create_quiz_for(HomeworkAssignee::Section::SECTION_C)
          @quiz_for_first_student             = create_quiz_for(HomeworkAssignee::Student::FIRST_STUDENT)
          @quiz_for_second_and_third_students = create_quiz_for([ HomeworkAssignee::Student::SECOND_STUDENT, HomeworkAssignee::Student::THIRD_STUDENT ])
          assign_quiz_overrides
          submit_quizzes
        end

        def all
          [
            self.quiz_for_everyone,
            self.quiz_for_section_a,
            self.quiz_for_section_b,
            self.quiz_for_section_c,
            self.quiz_for_sections_a_and_b,
            self.quiz_for_first_student,
            self.quiz_for_second_and_third_students
          ]
        end

        private

          def create_quiz_for(assignee)
            DifferentiatedAssignments::Quiz.new(assignee)
          end

          def assign_quiz_overrides
            self.all.each(&:assign_overrides)
          end

          def submit_quizzes
            users = DifferentiatedAssignments::Users
            self.quiz_for_everyone.submit_as(users.first_student)
            self.quiz_for_section_a.submit_as(users.first_student)
            self.quiz_for_section_b.submit_as(users.second_student)
            self.quiz_for_section_c.submit_as(users.fourth_student)
            self.quiz_for_sections_a_and_b.submit_as(users.third_student)
            self.quiz_for_first_student.submit_as(users.first_student)
            self.quiz_for_second_and_third_students.submit_as(users.second_student)
            self.quiz_for_second_and_third_students.submit_as(users.third_student)
          end
      end
    end
  end
end
