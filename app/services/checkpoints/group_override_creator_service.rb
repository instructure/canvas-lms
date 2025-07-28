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
  include Checkpoints::GroupOverrideCommon

  def initialize(checkpoint:, override:)
    super()
    @checkpoint = checkpoint
    @override = override
  end

  def call
    if differentiation_tag_override?(@override, @checkpoint)
      handle_differentiation_tag_override
    else
      handle_group_override
    end
  end

  private

  def handle_group_override
    if @checkpoint.effective_group_category_id.nil?
      raise Checkpoints::GroupAssignmentRequiredError, "must be a group assignment in order to create group overrides"
    end

    group = get_group_from_override(@override, @checkpoint)
    parent_override = parent_override(group)
    create_override(assignment: @checkpoint, group:, parent_override:)
  end

  def handle_differentiation_tag_override
    tag = get_differentiation_tag_from_override(@override, @checkpoint)
    parent_override = parent_override(tag)
    create_override(assignment: @checkpoint, group: tag, parent_override:)
  end

  def create_override(assignment:, group:, shell_override: false, parent_override: nil)
    override = assignment.assignment_overrides.build(set: group, dont_touch_assignment: true, parent_override:)
    apply_overridden_dates(override, @override, shell_override:)
    override.save!
    override
  end

  def parent_override(group)
    @checkpoint.parent_assignment.active_assignment_overrides.find_by(set: group) || create_override(assignment: @checkpoint.parent_assignment, group:, shell_override: true)
  end
end
