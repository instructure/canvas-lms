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

class CoursePacing::SectionPacePresenter < CoursePacing::PacePresenter
  attr_reader :section

  def initialize(section_pace, section = nil)
    super(section_pace)
    @section = section || @pace.course_section
  end

  def as_json
    default_json.merge({
                         section: {
                           name: section.name,
                           size: section.student_enrollments.count
                         }
                       })
  end

  private

  def context_id
    @section.id
  end

  def context_type
    "Section"
  end
end
