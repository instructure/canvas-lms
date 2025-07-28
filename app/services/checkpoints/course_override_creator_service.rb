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

class Checkpoints::CourseOverrideCreatorService < ApplicationService
  include Checkpoints::DateOverrider

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    course = @checkpoint.course

    parent_override = parent_override(course)
    create_override(assignment: @checkpoint, course:, parent_override:)
  end

  private

  def create_override(assignment:, course:, shell_override: false, parent_override: nil)
    override = assignment.assignment_overrides.build(set: course, dont_touch_assignment: true, parent_override:)
    apply_overridden_dates(override, @override, shell_override:)
    override.save!
    override
  end

  def parent_override(course)
    @checkpoint.parent_assignment.active_assignment_overrides.find_by(set: course) || create_override(assignment: @checkpoint.parent_assignment, course:, shell_override: true)
  end
end
