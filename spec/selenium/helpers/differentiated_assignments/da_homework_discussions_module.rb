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

require_relative "da_discussion"

module DifferentiatedAssignments
  module Homework
    module Discussions
      class << self
        attr_reader :discussion_for_everyone,
                    :discussion_for_section_a,
                    :discussion_for_section_b,
                    :discussion_for_sections_a_and_b,
                    :discussion_for_section_c,
                    :discussion_for_first_student,
                    :discussion_for_second_and_third_students

        def initialize
          @discussion_for_everyone                  = create_discussion_for(HomeworkAssignee::EVERYONE)
          @discussion_for_section_a                 = create_discussion_for(HomeworkAssignee::Section::SECTION_A)
          @discussion_for_section_b                 = create_discussion_for(HomeworkAssignee::Section::SECTION_B)
          @discussion_for_sections_a_and_b          = create_discussion_for([HomeworkAssignee::Section::SECTION_A,
                                                                             HomeworkAssignee::Section::SECTION_B])
          @discussion_for_section_c                 = create_discussion_for(HomeworkAssignee::Section::SECTION_C)
          @discussion_for_first_student             = create_discussion_for(HomeworkAssignee::Student::FIRST_STUDENT)
          @discussion_for_second_and_third_students = create_discussion_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                             HomeworkAssignee::Student::THIRD_STUDENT])
          assign_discussion_overrides
          submit_discussions
        end

        def short_list_initialize
          @discussion_for_sections_a_and_b          = create_discussion_for([HomeworkAssignee::Section::SECTION_A,
                                                                             HomeworkAssignee::Section::SECTION_B])
          @discussion_for_second_and_third_students = create_discussion_for([HomeworkAssignee::Student::SECOND_STUDENT,
                                                                             HomeworkAssignee::Student::THIRD_STUDENT])
          assign_discussion_overrides(short: true)
        end

        def all
          [
            discussion_for_everyone,
            discussion_for_section_a,
            discussion_for_section_b,
            discussion_for_sections_a_and_b,
            discussion_for_section_c,
            discussion_for_first_student,
            discussion_for_second_and_third_students
          ]
        end

        def short_list
          [
            discussion_for_sections_a_and_b,
            discussion_for_second_and_third_students
          ]
        end

        private

        def create_discussion_for(assignee)
          DifferentiatedAssignments::Discussion.new(assignee)
        end

        def assign_discussion_overrides(short = false)
          if short
            short_list.each(&:assign_overrides)
          else
            all.each(&:assign_overrides)
          end
        end

        def submit_discussions
          users = DifferentiatedAssignments::Users
          discussion_for_everyone.submit_as(users.first_student)
          discussion_for_section_a.submit_as(users.first_student)
          discussion_for_section_b.submit_as(users.second_student)
          discussion_for_sections_a_and_b.submit_as(users.third_student)
          discussion_for_section_c.submit_as(users.fourth_student)
          discussion_for_first_student.submit_as(users.first_student)
          discussion_for_second_and_third_students.submit_as(users.second_student)
          discussion_for_second_and_third_students.submit_as(users.third_student)
        end
      end
    end
  end
end
