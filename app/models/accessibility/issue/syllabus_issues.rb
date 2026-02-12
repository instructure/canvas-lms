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
    # TODO: RCX-4765 - This module is being added for API consistency with other resource types
    # (Announcements, WikiPages, etc.) but the Accessibility::Issue class that uses it is dead code.
    # The UI that consumed this data was removed in commit 70d63e25976.
    # The new accessibility checker uses AccessibilityResourceScan for syllabus scanning instead.
    # This is kept only for potential external API consumers.
    module SyllabusIssues
      def generate_syllabus_resources(skip_scan: false)
        # Syllabus is stored directly on the course context
        return {} if context.syllabus_body.blank?
        return syllabus_attributes if skip_scan

        result = check_content_accessibility(context.syllabus_body.to_s)
        { syllabus: result.merge(syllabus_attributes) }
      end

      private

      def syllabus_attributes
        {
          title: "Syllabus",
          published: context.published?,
          updated_at: context.updated_at.iso8601 || ""
        }.merge(resource_urls_for_syllabus)
      end

      def resource_urls_for_syllabus
        {
          url: "/courses/#{context.id}/syllabus",
          edit_url: "/courses/#{context.id}/syllabus/edit"
        }
      end
    end
  end
end
