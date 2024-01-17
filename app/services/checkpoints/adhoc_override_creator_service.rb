# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Checkpoints::AdhocOverrideCreatorService < ApplicationService
  include Checkpoints::DateOverrider

  class StudentIdsRequiredError < StandardError; end

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    desired_student_ids = @override.fetch(:student_ids) { raise StudentIdsRequiredError, "student_ids is required, but was not provided" }
    student_ids = @checkpoint.course.all_students.where(id: desired_student_ids).pluck(:id)
    override = build_override(assignment: @checkpoint, student_ids:)
    build_override_students(override:, student_ids:)
    override.save!

    parent_override = existing_parent_override || build_override(assignment: @checkpoint.parent_assignment, student_ids:, shell_override: true)
    build_override_students(override: parent_override, student_ids:)
    parent_override.save! if parent_override.changed? || parent_override.changed_student_ids.any?

    override
  end

  private

  def build_override(assignment:, student_ids:, shell_override: false)
    override = assignment.assignment_overrides.build(
      set_id: nil,
      set_type: AssignmentOverride::SET_TYPE_ADHOC,
      dont_touch_assignment: true
    )
    apply_overridden_dates(override, @override, shell_override:)
    override
  end

  def build_override_students(override:, student_ids:)
    override.changed_student_ids = Set.new
    existing_student_ids = override.assignment_override_students.pluck(:user_id)

    (student_ids - existing_student_ids).each do |user_id|
      override.assignment_override_students.build(user_id:)
      override.changed_student_ids << user_id
    end
  end

  def existing_parent_override
    @checkpoint.parent_assignment.active_assignment_overrides.find_by(set_type: AssignmentOverride::SET_TYPE_ADHOC)
  end
end
