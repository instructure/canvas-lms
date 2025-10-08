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

class PeerReview::SectionOverrideCreatorService < PeerReview::SectionOverrideCommonService
  def initialize(
    peer_review_sub_assignment: nil,
    override: nil
  )
    super
  end

  def call
    validate_override_dates(@override)

    section_id = fetch_set_id
    validate_set_id_present(section_id)

    section = course_section(section_id)
    validate_section_exists(section)

    create_override(section)
  end

  private

  def create_override(section)
    override = @peer_review_sub_assignment.assignment_overrides.build(
      set: section,
      unassign_item: fetch_unassign_item
    )
    apply_overridden_dates(override, @override)

    override.save!
    override
  end
end
