require_relative 'selective_release_discussion'

module SelectiveRelease
  module Homework
    module Discussions
      class << self
        attr_reader :course, :discussion_for_everyone, :discussion_for_section_a, :discussion_for_section_b,
          :discussion_for_sections_a_and_b, :discussion_for_section_c, :discussion_for_first_student,
          :discussion_for_second_and_third_students

        def initialize(course)
          @course                                   = course
          @discussion_for_everyone                  = create_discussion_for(HomeworkAssignee::EVERYONE)
          @discussion_for_section_a                 = create_discussion_for(HomeworkAssignee::Section::SECTION_A)
          @discussion_for_section_b                 = create_discussion_for(HomeworkAssignee::Section::SECTION_B)
          @discussion_for_sections_a_and_b          = create_discussion_for([ HomeworkAssignee::Section::SECTION_A, HomeworkAssignee::Section::SECTION_B ])
          @discussion_for_section_c                 = create_discussion_for(HomeworkAssignee::Section::SECTION_C)
          @discussion_for_first_student             = create_discussion_for(HomeworkAssignee::Student::FIRST_STUDENT)
          @discussion_for_second_and_third_students = create_discussion_for([ HomeworkAssignee::Student::SECOND_STUDENT, HomeworkAssignee::Student::THIRD_STUDENT ])
          assign_discussion_overrides
          submit_discussions
        end

        def all
          [
            self.discussion_for_everyone,
            self.discussion_for_section_a,
            self.discussion_for_section_b,
            self.discussion_for_sections_a_and_b,
            self.discussion_for_section_c,
            self.discussion_for_first_student,
            self.discussion_for_second_and_third_students
          ]
        end

        private

          def create_discussion_for(assignee)
            SelectiveRelease::Discussion.new(self.course, assignee)
          end

          def assign_discussion_overrides
            self.all.each(&:assign_overrides)
          end

          def submit_discussions
            self.discussion_for_everyone.submit_as(SelectiveRelease::Users.first_student)
            self.discussion_for_section_a.submit_as(SelectiveRelease::Users.first_student)
            self.discussion_for_section_b.submit_as(SelectiveRelease::Users.second_student)
            self.discussion_for_sections_a_and_b.submit_as(SelectiveRelease::Users.third_student)
            self.discussion_for_section_c.submit_as(SelectiveRelease::Users.fourth_student)
            self.discussion_for_first_student.submit_as(SelectiveRelease::Users.first_student)
            self.discussion_for_second_and_third_students.submit_as(SelectiveRelease::Users.second_student)
            self.discussion_for_second_and_third_students.submit_as(SelectiveRelease::Users.third_student)
          end
      end
    end
  end
end