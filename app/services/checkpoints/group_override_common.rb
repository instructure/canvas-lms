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

module Checkpoints::GroupOverrideCommon
  # Differentiaiton tags are allowed to be used as group overrides
  # This method determines if the override is associated with a
  # differentiation tag in the checkpoint's course
  def differentiation_tag_override?(override, checkpoint)
    return false unless differentiation_tags_enabled_for_context?(checkpoint)

    group = get_differentiation_tag_from_override(override, checkpoint)

    if group.nil?
      return false
    end

    group.non_collaborative
  end

  def get_group_from_override(override, checkpoint)
    group_id = override.fetch(:set_id) { raise Checkpoints::SetIdRequiredError, "set_id is required, but was not provided" }
    checkpoint.course.active_groups.where(group_category_id: checkpoint.effective_group_category_id).find(group_id)
  end

  def get_differentiation_tag_from_override(override, checkpoint)
    tag_id = override.fetch(:set_id) { raise Checkpoints::SetIdRequiredError, "set_id is required, but was not provided" }
    checkpoint.course.differentiation_tags.where(id: tag_id).first
  end

  private

  def differentiation_tags_enabled_for_context?(checkpoint)
    account = checkpoint.course.account
    account.feature_enabled?(:assign_to_differentiation_tags) && account.allow_assign_to_differentiation_tags?
  end
end
