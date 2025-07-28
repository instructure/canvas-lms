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

class Checkpoints::CourseOverrideUpdaterService < ApplicationService
  include Checkpoints::DateOverrider

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    override = @checkpoint.assignment_overrides.find_by(id: @override[:id], set_type: AssignmentOverride::SET_TYPE_COURSE)
    raise Checkpoints::OverrideNotFoundError unless override

    course = @checkpoint.course

    update_override(override:)

    parent_override = @checkpoint.parent_assignment.active_assignment_overrides.find_by(set: course)
    raise Checkpoints::OverrideNotFoundError unless parent_override

    update_override(override: parent_override, shell_override: true)

    override
  end

  def update_override(override:, shell_override: false)
    apply_overridden_dates(override, @override, shell_override:)
    override.save!
    override
  end
end
