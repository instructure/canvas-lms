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

class PeerReview::GroupOverrideUpdaterService < PeerReview::GroupOverrideCommonService
  def call
    validate_override_dates(@override)

    override = find_override
    validate_override_exists(override)

    # Fall back to getting set id from the override
    set_id = fetch_set_id || override.set_id
    validate_set_id_required(set_id)

    is_differentiation_tag_override = differentiation_tag_override?(set_id)

    # Peer review sub assignment inherits group_category_id from parent assignment
    validate_group_assignment_required(@peer_review_sub_assignment) unless is_differentiation_tag_override

    group = if is_differentiation_tag_override
              find_differentiation_tag(set_id)
            else
              find_group(set_id)
            end
    validate_group_exists(group)

    update_override(override, group)
  end

  private

  def update_override(override, group)
    override.set = group if group.id != override.set_id
    apply_overridden_dates(override, @override)

    override.save! if override.changed?
    override
  end

  def find_override
    @peer_review_sub_assignment.assignment_overrides.find_by(
      id: fetch_id,
      set_type: AssignmentOverride::SET_TYPE_GROUP
    )
  end
end
