# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module Api::V1::AvailabilityStatus
  def calculate_availability_status(unlock_at, lock_at)
    now = Time.zone.now

    if unlock_at && unlock_at > now
      { status: "pending", date: unlock_at }
    elsif lock_at && lock_at < now
      { status: "closed", date: nil }
    elsif lock_at
      { status: "open", date: lock_at }
    else
      { status: nil, date: nil }
    end
  end
end
