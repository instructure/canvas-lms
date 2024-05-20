# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::SectionPaceService < CoursePacing::PaceService
  class << self
    def paces_in_course(course)
      course.course_paces.not_deleted.section_paces.preload(:course_section)
    end

    def pace_in_context(section)
      paces_in_course(course_for(section)).find_by(course_section_id: section.id)
    end

    def template_pace_for(section)
      course_for(section).course_paces.primary.take
    end

    def create_params(section)
      super.merge({ course_section_id: section.id })
    end

    def course_for(section)
      section.course
    end
  end
end
