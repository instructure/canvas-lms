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

module DifferentiatedAssignments
  module HomeworkAssignee
    module Group
      BASE    = "Group"
      GROUP_X = "#{BASE} A".freeze
      GROUP_Y = "#{BASE} B".freeze
      GROUP_Z = "#{BASE} C".freeze
      ALL     = Group.constants.map { |c| Group.const_get(c) }
                     .reject { |c| c == Group::BASE }
                     .freeze
    end

    module Section
      BASE      = "Section"
      SECTION_A = "#{BASE} A".freeze
      SECTION_B = "#{BASE} B".freeze
      SECTION_C = "#{BASE} C".freeze
      ALL       = Section.constants.map { |c| Section.const_get(c) }
                         .reject { |c| c == Section::BASE }
                         .freeze
    end

    module Student
      BASE           = "Student"
      FIRST_STUDENT  = "#{BASE} 1".freeze
      SECOND_STUDENT = "#{BASE} 2".freeze
      THIRD_STUDENT  = "#{BASE} 3".freeze
      FOURTH_STUDENT = "#{BASE} 4".freeze
      ALL            = Student.constants.map { |c| Student.const_get(c) }
                              .reject { |c| c == Student::BASE }
                              .freeze
    end

    EVERYONE  = "Everyone"
    ALL       = HomeworkAssignee.constants.map { |c| HomeworkAssignee.const_get(c) }

    ASSIGNEES = [
      HomeworkAssignee::Student::ALL,
      HomeworkAssignee::Section::ALL,
      HomeworkAssignee::Group::ALL,
      HomeworkAssignee::ALL
    ].freeze

    ASSIGNEE_TYPES = [
      HomeworkAssignee::EVERYONE,
      HomeworkAssignee::Group::BASE,
      HomeworkAssignee::Section::BASE,
      HomeworkAssignee::Student::BASE
    ].freeze
  end
end
