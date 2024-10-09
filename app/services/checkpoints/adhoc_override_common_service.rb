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

class Checkpoints::AdhocOverrideCommonService < ApplicationService
  require_relative "discussion_checkpoint_error"
  include Checkpoints::DateOverrider

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  private

  def build_override_students(override:, student_ids:)
    override.changed_student_ids = Set.new
    existing_student_ids = override.assignment_override_students.pluck(:user_id)

    (student_ids - existing_student_ids).each do |user_id|
      override.assignment_override_students.build(user_id:)
      override.changed_student_ids << user_id
    end
  end

  def existing_parent_override(student_ids:)
    subquery = AssignmentOverrideStudent
               .select(:assignment_override_id)
               .where(user_id: student_ids, assignment_id: @checkpoint.parent_assignment.id)
               .group(:assignment_override_id)
               .having("COUNT(DISTINCT user_id) = ?", student_ids.size)

    @checkpoint.parent_assignment.reload.active_assignment_overrides
               .where(set_type: "ADHOC", id: subquery)
               .first
  end

  def get_title(student_ids:)
    I18n.t({ one: "1 student", other: "%{count} students" }, count: student_ids.size)
  end
end
