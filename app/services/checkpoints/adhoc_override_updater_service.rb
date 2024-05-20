# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Checkpoints::AdhocOverrideUpdaterService < Checkpoints::AdhocOverrideCommonService
  def call
    desired_student_ids = @override.fetch(:student_ids) { raise Checkpoints::StudentIdsRequiredError, "student_ids is required, but was not provided" }
    raise Checkpoints::StudentIdsRequiredError, "student_ids is required, but was not provided" if desired_student_ids.blank?

    override = @checkpoint.assignment_overrides.find_by(id: @override[:id], set_type: AssignmentOverride::SET_TYPE_ADHOC)
    raise Checkpoints::OverrideNotFoundError unless override

    valid_student_ids = @checkpoint.course.all_students.where(id: desired_student_ids).pluck(:id)
    existing_student_ids = override.assignment_override_students.pluck(:user_id)
    student_ids_to_delete = existing_student_ids - valid_student_ids

    apply_overridden_dates(override, @override, shell_override: false)

    build_override_students(override:, student_ids: valid_student_ids)
    override.save! if override.changed? || override.changed_student_ids.any?

    override.assignment_override_students.where(user_id: student_ids_to_delete).destroy_all if student_ids_to_delete.any?

    parent_override = existing_parent_override
    build_override_students(override: parent_override, student_ids: valid_student_ids)
    parent_override.save! if parent_override.changed? || parent_override.changed_student_ids.any?

    parent_override.assignment_override_students.where(user_id: student_ids_to_delete).destroy_all if student_ids_to_delete.any?

    override
  end
end
