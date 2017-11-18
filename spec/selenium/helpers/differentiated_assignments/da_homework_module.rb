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

require_relative 'da_homework_assignments_module'
require_relative 'da_homework_discussions_module'
require_relative 'da_homework_quizzes_module'

module DifferentiatedAssignments
  module Homework
    class << self

      def initialize
        DifferentiatedAssignments::Homework::Assignments.initialize
        DifferentiatedAssignments::Homework::Discussions.initialize
        DifferentiatedAssignments::Homework::Quizzes.initialize
      end

      def short_list_initialize
        DifferentiatedAssignments::Homework::Assignments.short_list_initialize
        DifferentiatedAssignments::Homework::Discussions.short_list_initialize
        DifferentiatedAssignments::Homework::Quizzes.short_list_initialize
      end
    end
  end
end
