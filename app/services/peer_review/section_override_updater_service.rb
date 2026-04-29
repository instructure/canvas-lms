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

class PeerReview::SectionOverrideUpdaterService < PeerReview::SectionOverrideCommonService
  def call
    validate_peer_review_dates(@override)

    override = find_override
    validate_override_exists(override)

    section_id = fetch_set_id || override.set_id
    validate_set_id_required(section_id)

    section = course_section(section_id)
    validate_section_exists(section)

    ActiveRecord::Base.transaction do
      parent_override = if section_id == override.set_id
                          override.parent_override
                        else
                          find_parent_override(section_id)
                        end
      validate_section_parent_override_exists(parent_override, section_id)

      validate_override_dates_against_parent_override(@override, parent_override)

      update_override(override, section, parent_override)
    end
  end

  private

  def update_override(override, section, parent_override)
    override.set = section unless section.id == override.set_id
    override.parent_override = parent_override
    apply_overridden_dates(override, @override)

    override.save! if override.changed?
    override
  end

  def find_override
    @peer_review_sub_assignment.active_assignment_overrides.find_by(
      id: fetch_id,
      set_type: AssignmentOverride::SET_TYPE_COURSE_SECTION
    )
  end
end
