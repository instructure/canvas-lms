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

class Checkpoints::GroupOverrideCreatorService < ApplicationService
  require_relative "discussion_checkpoint_error"
  include Checkpoints::DateOverrider

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    if @checkpoint.effective_group_category_id.nil?
      raise Checkpoints::GroupAssignmentRequiredError, "must be a group assignment in order to create group overrides"
    end

    group_id = @override.fetch(:set_id) { raise Checkpoints::SetIdRequiredError, "set_id is required, but was not provided" }
    group = @checkpoint.course.active_groups.where(group_category_id: @checkpoint.effective_group_category_id).find(group_id)
    override = create_override(assignment: @checkpoint, group:)

    unless parent_override_exists?(group)
      create_override(assignment: @checkpoint.parent_assignment, group:, shell_override: true)
    end

    override
  end

  private

  def create_override(assignment:, group:, shell_override: false)
    override = assignment.assignment_overrides.build(set: group, dont_touch_assignment: true)
    apply_overridden_dates(override, @override, shell_override:)
    override.save!
    override
  end

  def parent_override_exists?(group)
    @checkpoint.parent_assignment.active_assignment_overrides.where(set: group).exists?
  end
end
