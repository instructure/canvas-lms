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

class PeerReview::GroupOverrideCommonService < ApplicationService
  include PeerReview::Validations
  include PeerReview::DateOverrider

  def initialize(
    peer_review_sub_assignment: nil,
    override: nil
  )
    super()

    @peer_review_sub_assignment = peer_review_sub_assignment
    @override = override || {}
  end

  private

  def differentiation_tag_override?(set_id)
    return false unless differentiation_tags_enabled_for_context?

    group = find_differentiation_tag(set_id)
    return false if group.nil?

    group.non_collaborative
  end

  def find_differentiation_tag(tag_id)
    course.differentiation_tags.find_by(id: tag_id)
  end

  def find_group(group_id)
    group_category_id = @peer_review_sub_assignment.group_category_id

    course.active_groups.where(group_category_id:).find_by(id: group_id)
  end

  def differentiation_tags_enabled_for_context?
    account.allow_assign_to_differentiation_tags?
  end

  def course
    @course ||= @peer_review_sub_assignment.course
  end

  def account
    @account ||= course.account
  end

  def fetch_id
    @override.fetch(:id, nil)
  end

  def fetch_set_id
    @override.fetch(:set_id, nil)
  end

  def find_parent_override(group_id)
    parent_assignment.active_assignment_overrides.find_by(
      set_id: group_id,
      set_type: AssignmentOverride::SET_TYPE_GROUP
    )
  end

  def parent_assignment
    @peer_review_sub_assignment.parent_assignment
  end
end
