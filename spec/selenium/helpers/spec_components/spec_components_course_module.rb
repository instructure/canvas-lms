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

module SpecComponents
  class CourseModule
    attr_reader :course, :name

    def initialize(course, module_name)
      @course = course
      @component_course_module = @course.context_modules.create!(name: module_name)
      @name = @component_course_module.name
    end

    def add_assignment(assignment)
      @component_course_module.add_item(id: assignment.id, type: 'assignment')
    end

    def add_quiz(quiz)
      @component_course_module.add_item(id: quiz.id, type: 'quiz')
    end

    def add_discussion(discussion)
      @component_course_module.add_item(id: discussion.id, type: 'discussion')
    end
  end
end
