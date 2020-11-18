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
  module Sections
    class << self
      attr_reader :section_a, :section_b, :section_c

      def initialize
        @section_a = create_section('Section A')
        @section_b = create_section('Section B')
        @section_c = create_section('Section C')
      end

      private

        def create_section(section_name)
          DifferentiatedAssignments.the_course.course_sections.create!(name: section_name)
        end
    end
  end
end
