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

class Accessibility::CourseScannerService < ApplicationService
  def initialize(course:)
    super()
    @course = course
  end

  def call
    delay(singleton: "accessibility_scan_course_#{@course.global_id}").scan_course
  end

  def scan_course
    if @course.exceeds_accessibility_scan_limit?
      Rails.logger.warn(
        "[A11Y Scan] Skipped scanning the course #{@course.name} (ID: #{@course.id}) due to exceeding the size limit."
      )
      return
    end

    @course.wiki_pages.not_deleted.find_each do |resource|
      Accessibility::ResourceScannerService.call(resource:)
    end
    @course.assignments.active.except(:order).find_each do |resource|
      Accessibility::ResourceScannerService.call(resource:)
    end
  end
end
