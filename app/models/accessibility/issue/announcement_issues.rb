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
module Accessibility
  class Issue
    module AnnouncementIssues
      def generate_announcement_resources(skip_scan: false)
        announcements = context.announcements.active
        return announcements.map { |announcement| announcement_attributes(announcement) } if skip_scan

        announcements.each_with_object({}) do |announcement, issues|
          result = check_content_accessibility(announcement.message.to_s)
          issues[announcement.id] = result.merge(announcement_attributes(announcement))
        end
      end

      private

      def announcement_attributes(announcement)
        {
          title: announcement.title,
          published: announcement.published?,
          updated_at: announcement.updated_at.iso8601 || ""
        }.merge(resource_urls(announcement))
      end
    end
  end
end
