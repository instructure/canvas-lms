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

class Accessibility::RootAccountScannerService < ApplicationService
  # Maximum number of courses to be scanned for the root account
  MAX_COURSE_COUNT = 1000

  def initialize(account:)
    super()
    @account = account
  end

  def call
    delay(singleton: "accessibility_scan_account_#{@account.global_id}").scan_account
  end

  def scan_account
    unless @account.root_account?
      Rails.logger.warn("[A11Y Scan] Failed to scan account #{@account.global_id}: account must be a root account.")
      return
    end

    ids = @account
          .all_courses
          .active
          .not_completed
          .order(id: :desc)
          .limit(MAX_COURSE_COUNT)
          .pluck(:id)
    Course.where(id: ids)
          .find_each do |course|
      Accessibility::CourseScannerService.call(course:)
    end
  end
end
