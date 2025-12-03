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
#

class PeerReview::DateOverrideCommonService < ApplicationService
  include PeerReview::Validations

  def initialize(
    peer_review_sub_assignment: nil,
    overrides: nil
  )
    super()

    @peer_review_sub_assignment = peer_review_sub_assignment
    @overrides = overrides || []
  end

  def call
    existing_overrides = preload_existing_overrides || {}

    @overrides.each do |override|
      id = override.fetch(:id, nil)
      set_type = override.fetch(:set_type, nil)

      # For existing overrides, get set_type from the override if not provided
      if id.present? && set_type.nil?
        existing_override = existing_overrides[id]
        validate_override_exists(existing_override)

        set_type = existing_override.set_type
      end

      validate_set_type_required(set_type)
      validate_set_type_supported(set_type, services)

      service = services.fetch(set_type)
      service.call(
        peer_review_sub_assignment: @peer_review_sub_assignment,
        override:
      )
    end
  end

  private

  def services
    {}
  end

  def preload_existing_overrides
    return if @overrides.empty?

    existing_ids = @overrides.filter_map { |override| override.fetch(:id, nil) }
    return if existing_ids.empty?

    @peer_review_sub_assignment
      .active_assignment_overrides
      .where(id: existing_ids)
      .index_by(&:id)
  end
end
