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

class CoursePacing::PaceContextsPresenter
  def self.as_json(pace_context)
    {
      name: display_name_for(pace_context),
      type: pace_context.class_name,
      item_id: pace_context.id,
      associated_section_count: pace_context.try(:course_sections).try(:count),
      associated_student_count: pace_context.try(:student_enrollments).try(:count),
      applied_pace: applied_pace_for(pace_context)
    }
  end

  def self.display_name_for(pace_context)
    case pace_context
    when Course, CourseSection
      pace_context.name
    when StudentEnrollment
      pace_context.user.name
    end
  end

  def self.applied_pace_for(pace_context)
    applied_pace = CoursePacing::PaceService.for(pace_context).pace_for(pace_context)

    return nil unless applied_pace

    {
      name: applied_pace.effective_name,
      type: applied_pace.type,
      duration: applied_pace.duration,
      last_modified: applied_pace.published_at&.utc
    }
  end
end
