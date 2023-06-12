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

require_relative "da_sections_module"
require_relative "da_users_module"
require_relative "da_homework_module"
require_relative "da_course_modules_module"

# Differentiated Assignments is AKA Selective Release
module DifferentiatedAssignments
  class << self
    attr_reader :the_course

    def initialize
      @the_course = create_course
      DifferentiatedAssignments::Sections.initialize
      DifferentiatedAssignments::Users.initialize
      DifferentiatedAssignments::Homework.initialize
      DifferentiatedAssignments::CourseModules.initialize
    end

    def short_list_initialize
      @the_course = create_course
      DifferentiatedAssignments::Sections.initialize
      DifferentiatedAssignments::Users.initialize
      DifferentiatedAssignments::Homework.short_list_initialize
    end

    private

    include Factories

    def create_course(opts = {})
      course_name = opts.fetch(:name, "Selective Release Course")
      course_factory(
        course_name:,
        active_course: true
      )
    end
  end

  module URLs
    class << self
      def course_home_page
        "/courses/#{DifferentiatedAssignments.the_course.id}"
      end

      def quiz_show_page(quiz)
        "#{quizzes_index_page}/#{quiz.id}"
      end

      def quizzes_index_page
        "#{course_home_page}/quizzes"
      end

      def assignment_show_page(assignment)
        "#{assignments_index_page}/#{assignment.id}"
      end

      def assignments_index_page
        "#{course_home_page}/assignments"
      end

      def discussion_show_page(discussion)
        "#{discussions_index_page}/#{discussion.id}"
      end

      def discussions_index_page
        "#{course_home_page}/discussions"
      end

      def course_module_show_page(course_module)
        "#{course_modules_index_page}/#{course_module.id}"
      end

      def course_modules_index_page
        "#{course_home_page}/modules"
      end
    end
  end
end
