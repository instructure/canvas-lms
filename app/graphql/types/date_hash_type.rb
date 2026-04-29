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

module Types
  class DateHashSetType < ApplicationObjectType
    description "Set information for a date hash entry"

    field :id, ID, null: true
    field :type, String, null: true
  end

  class DateHashType < ApplicationObjectType
    description "Standardized date hash from backend assigned_to_dates field"

    field :base, Boolean, null: true
    field :due_at, DateTimeType, null: true
    field :id, ID, null: true
    field :lock_at, DateTimeType, null: true
    field :peer_review_dates, PeerReviewDatesType, null: true
    field :set, DateHashSetType, null: true
    field :title, String, null: true
    field :unlock_at, DateTimeType, null: true

    def set
      return nil unless object[:set_id] || object[:set_type]

      {
        id: object[:set_id],
        type: object[:set_type]
      }
    end

    def peer_review_dates
      return nil unless object[:peer_review_dates]

      object[:peer_review_dates]
    end
  end
end
