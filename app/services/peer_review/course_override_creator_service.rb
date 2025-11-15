# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class PeerReview::CourseOverrideCreatorService < PeerReview::CourseOverrideCommonService
  def call
    validate_override_dates(@override)

    course = @peer_review_sub_assignment.course
    validate_course_exists(course)

    ActiveRecord::Base.transaction do
      parent_override = find_parent_override(course.id)
      validate_course_parent_override_exists(parent_override, course.id)

      create_override(course, parent_override)
    end
  end

  private

  def create_override(course, parent_override)
    override = @peer_review_sub_assignment.assignment_overrides.build(
      set: course,
      dont_touch_assignment: true,
      parent_override:
    )
    apply_overridden_dates(override, @override)

    override.save!
    override
  end
end
