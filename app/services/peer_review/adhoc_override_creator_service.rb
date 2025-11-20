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

class PeerReview::AdhocOverrideCreatorService < PeerReview::AdhocOverrideCommonService
  def call
    validate_override_dates(@override)

    provided_student_ids = fetch_student_ids
    validate_student_ids_required(provided_student_ids)

    provided_student_ids_in_course = find_student_ids_in_course(provided_student_ids)
    validate_student_ids_in_course(provided_student_ids_in_course)

    ActiveRecord::Base.transaction do
      parent_override = find_parent_override(provided_student_ids_in_course)
      validate_adhoc_parent_override_exists(parent_override, provided_student_ids_in_course)

      override = build_override(provided_student_ids_in_course, parent_override)
      build_override_students(override, provided_student_ids_in_course)

      override.save!
      override
    end
  end

  private

  def build_override(student_ids, parent_override)
    override = @peer_review_sub_assignment.assignment_overrides.build(
      set_id: nil,
      set_type: AssignmentOverride::SET_TYPE_ADHOC,
      dont_touch_assignment: true,
      title: override_title(student_ids),
      unassign_item: fetch_unassign_item,
      parent_override:
    )
    apply_overridden_dates(override, @override)

    override
  end
end
