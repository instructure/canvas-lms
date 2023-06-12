# frozen_string_literal: true

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

require_relative "da_quiz"

module DifferentiatedAssignments
  module Homework
    module Quizzes
      class << self
        attr_reader :quiz_for_everyone,
                    :quiz_for_section_a,
                    :quiz_for_section_b,
                    :quiz_for_section_c,
                    :quiz_for_sections_a_and_b,
                    :quiz_for_first_student,
                    :quiz_for_second_and_third_students

        def initialize
          @quiz_for_everyone                  = create_quiz_for(HomeworkAssignee::EVERYONE)
          @quiz_for_section_a                 = create_quiz_for(HomeworkAssignee::Section::SECTION_A)
          @quiz_for_section_b                 = create_quiz_for(HomeworkAssignee::Section::SECTION_B)
          @quiz_for_sections_a_and_b          = create_quiz_for([HomeworkAssignee::Section::SECTION_A,
                                                                 HomeworkAssignee::Section::SECTION_B])
          @quiz_for_section_c                 = create_quiz_for(HomeworkAssignee::Section::SECTION_C)
          @quiz_for_first_student             = create_quiz_for(HomeworkAssignee::Student::FIRST_STUDENT)
          @quiz_for_second_and_third_students = create_quiz_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                 HomeworkAssignee::Student::THIRD_STUDENT])
          assign_quiz_overrides
          submit_quizzes
        end

        def short_list_initialize
          @quiz_for_sections_a_and_b          = create_quiz_for([HomeworkAssignee::Section::SECTION_A,
                                                                 HomeworkAssignee::Section::SECTION_B])
          @quiz_for_second_and_third_students = create_quiz_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                 HomeworkAssignee::Student::THIRD_STUDENT])
          assign_quiz_overrides(short: true)
        end

        def all
          [
            quiz_for_everyone,
            quiz_for_section_a,
            quiz_for_section_b,
            quiz_for_section_c,
            quiz_for_sections_a_and_b,
            quiz_for_first_student,
            quiz_for_second_and_third_students
          ]
        end

        def short_list
          [
            quiz_for_sections_a_and_b,
            quiz_for_second_and_third_students
          ]
        end

        private

        def create_quiz_for(assignee)
          DifferentiatedAssignments::Quiz.new(assignee)
        end

        def assign_quiz_overrides(short = flase)
          if short
            short_list.each(&:assign_overrides)
          else
            all.each(&:assign_overrides)
          end
        end

        def submit_quizzes
          users = DifferentiatedAssignments::Users
          quiz_for_everyone.submit_as(users.first_student)
          quiz_for_section_a.submit_as(users.first_student)
          quiz_for_section_b.submit_as(users.second_student)
          quiz_for_section_c.submit_as(users.fourth_student)
          quiz_for_sections_a_and_b.submit_as(users.third_student)
          quiz_for_first_student.submit_as(users.first_student)
          quiz_for_second_and_third_students.submit_as(users.second_student)
          quiz_for_second_and_third_students.submit_as(users.third_student)
        end
      end
    end
  end
end
