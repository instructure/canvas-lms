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

class Accessibility::BulkCloseIssuesService < ApplicationService
  def initialize(scan:, user_id:, close:)
    super()
    @scan = scan
    @user_id = user_id
    @close = close
  end

  def call
    if close
      close_issues
    else
      reopen_issues
    end
  end

  private

  attr_reader :scan, :user_id, :close

  def close_issues
    scan.bulk_close_issues!(user_id:)
  end

  def reopen_issues
    raise "Resource is not closed" if scan.open?

    # Reset closed status
    scan.update!(closed_at: nil)

    # Trigger a fresh re-scan
    # This will:
    # - Delete all rescannable issues (active + closed)
    # - Scan the resource for current issues
    # - Create new active issues
    # - Update issue_count
    # - Reset closed_at to nil
    Accessibility::ResourceScannerService.call(resource: scan.context)
  end
end
