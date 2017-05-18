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

require_relative '../spec_components/spec_components_course_module'

module DifferentiatedAssignments
  module CourseModules
    class << self
      attr_reader :first_module, :second_module, :third_module, :fourth_module

      def initialize
        @first_module  = create_course_module('Module 0')
        @second_module = create_course_module('Module 1') # TODO: Add prerequisite complete Module 0 first
        @third_module  = create_course_module('Module 2')
        @fourth_module = create_course_module('Module 3')
        add_assignments_to_modules
      end

      private

        def create_course_module(module_name)
          SpecComponents::CourseModule.new(DifferentiatedAssignments.the_course, module_name)
        end

        def add_assignments_to_modules
          assignments = DifferentiatedAssignments::Homework::Assignments
          self.first_module.add_assignment(assignments.assignment_for_section_a)
          self.first_module.add_assignment(assignments.assignment_for_section_b)
          self.first_module.add_assignment(assignments.assignment_for_first_student)

          quizzes = DifferentiatedAssignments::Homework::Quizzes
          self.second_module.add_quiz(quizzes.quiz_for_section_a)
          self.second_module.add_quiz(quizzes.quiz_for_section_b)
          self.second_module.add_quiz(quizzes.quiz_for_second_and_third_students)

          discussions = DifferentiatedAssignments::Homework::Discussions
          self.third_module.add_discussion(discussions.discussion_for_section_a)
          self.third_module.add_discussion(discussions.discussion_for_section_b)
          self.third_module.add_discussion(discussions.discussion_for_first_student)

          self.fourth_module.add_assignment(assignments.assignment_for_section_c)
        end
    end
  end
end
