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

class PeerReview::CourseOverrideCommonService < ApplicationService
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

  def fetch_id
    @override.fetch(:id, nil)
  end
end
