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

class Checkpoints::SectionOverrideUpdaterService < ApplicationService
  include Checkpoints::DateOverrider

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    section_id = @override.fetch(:set_id) { raise Checkpoints::SetIdRequiredError, "set_id is required, but was not provided" }
    raise Checkpoints::SetIdRequiredError, "set_id is required, but was not provided" if section_id.blank?

    section = @checkpoint.course.active_course_sections.find(section_id)
    override = @checkpoint.assignment_overrides.find_by(id: @override[:id], set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION)
    raise Checkpoints::OverrideNotFoundError unless override

    current_section = override.set

    update_override(override:, section:)

    parent_override = @checkpoint.parent_assignment.active_assignment_overrides.find_by(set: current_section)
    raise Checkpoints::OverrideNotFoundError unless parent_override

    update_override(override: parent_override, section:, shell_override: true)

    override
  end

  def update_override(override:, section:, shell_override: false)
    override.set = section if section.id != override.set_id
    apply_overridden_dates(override, @override, shell_override:)
    override.save!
    override
  end
end
