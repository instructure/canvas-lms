#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative 'da_assignment'

module DifferentiatedAssignments
  module Homework
    module Assignments
      class << self
        attr_reader :assignment_for_everyone, :assignment_for_section_a,
          :assignment_for_section_b, :assignment_for_sections_a_and_b,
          :assignment_for_section_c, :assignment_for_first_student,
          :assignment_for_second_and_third_students

        def initialize
          @assignment_for_everyone                  = create_assignment_for(HomeworkAssignee::EVERYONE)
          @assignment_for_section_a                 = create_assignment_for(HomeworkAssignee::Section::SECTION_A)
          @assignment_for_section_b                 = create_assignment_for(HomeworkAssignee::Section::SECTION_B)
          @assignment_for_sections_a_and_b          = create_assignment_for([HomeworkAssignee::Section::SECTION_A,
                                                                             HomeworkAssignee::Section::SECTION_B ])
          @assignment_for_section_c                 = create_assignment_for(HomeworkAssignee::Section::SECTION_C)
          @assignment_for_first_student             = create_assignment_for(HomeworkAssignee::Student::FIRST_STUDENT)
          @assignment_for_second_and_third_students = create_assignment_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                             HomeworkAssignee::Student::THIRD_STUDENT ])
          assign_assignment_overrides
          submit_assignments
        end

        def short_list_initialize
          @assignment_for_sections_a_and_b          = create_assignment_for([HomeworkAssignee::Section::SECTION_A,
                                                                             HomeworkAssignee::Section::SECTION_B ])
          @assignment_for_second_and_third_students = create_assignment_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                             HomeworkAssignee::Student::THIRD_STUDENT ])
          assign_assignment_overrides(short: true)
        end

        def all
          [
            self.assignment_for_everyone,
            self.assignment_for_section_a,
            self.assignment_for_section_b,
            self.assignment_for_sections_a_and_b,
            self.assignment_for_section_c,
            self.assignment_for_first_student,
            self.assignment_for_second_and_third_students
          ]
        end

        def short_list
          [
            self.assignment_for_sections_a_and_b,
            self.assignment_for_second_and_third_students
          ]
        end

        private

          def create_assignment_for(assignee)
            DifferentiatedAssignments::Assignment.new(assignee)
          end

          def assign_assignment_overrides(short=false)
            if short
              self.short_list.each(&:assign_overrides)
            else
              self.all.each(&:assign_overrides)
            end
          end

          def submit_assignments
            users = DifferentiatedAssignments::Users
            self.assignment_for_everyone.submit_as(users.first_student)
            self.assignment_for_section_a.submit_as(users.first_student)
            self.assignment_for_section_b.submit_as(users.second_student)
            self.assignment_for_sections_a_and_b.submit_as(users.third_student)
            self.assignment_for_section_c.submit_as(users.fourth_student)
            self.assignment_for_first_student.submit_as(users.first_student)
            self.assignment_for_second_and_third_students.submit_as(users.second_student)
            self.assignment_for_second_and_third_students.submit_as(users.third_student)
          end
      end
    end
  end
end
