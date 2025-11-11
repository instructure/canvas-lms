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

class PeerReview::AdhocOverrideUpdaterService < PeerReview::AdhocOverrideCommonService
  def call
    validate_override_dates(@override)

    override = find_override
    validate_override_exists(override)

    # Fall back to getting student ids from the override set
    provided_student_ids = fetch_student_ids || override.set&.map(&:id)
    validate_student_ids_required(provided_student_ids)

    provided_student_ids_in_course = find_student_ids_in_course(provided_student_ids)
    validate_student_ids_in_course(provided_student_ids_in_course)

    existing_student_ids = override.assignment_override_students.pluck(:user_id).uniq
    student_ids_to_delete = existing_student_ids - provided_student_ids_in_course

    ActiveRecord::Base.transaction do
      parent_override = if provided_student_ids_in_course.sort == existing_student_ids.sort
                          override.parent_override
                        else
                          find_parent_override(provided_student_ids_in_course)
                        end
      validate_adhoc_parent_override_exists(parent_override, provided_student_ids_in_course)

      destroy_override_students(override, student_ids_to_delete) if student_ids_to_delete.any?
      update_override(override, provided_student_ids_in_course, parent_override)
    end

    override
  end

  def destroy_override_students(override, student_ids)
    return if student_ids.blank?

    override.assignment_override_students.where(user_id: student_ids).destroy_all
  end

  def update_override(override, student_ids, parent_override)
    override.title = override_title(student_ids)
    override.parent_override = parent_override

    build_override_students(override, student_ids)
    apply_overridden_dates(override, @override)

    override.save! if override.changed? || override&.changed_student_ids&.any?
    override
  end

  def find_override
    @peer_review_sub_assignment.active_assignment_overrides.find_by(
      id: fetch_id,
      set_type: AssignmentOverride::SET_TYPE_ADHOC
    )
  end
end
