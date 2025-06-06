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
    module PageIssues
      def generate_page_issues
        context.wiki_pages.not_deleted.order(updated_at: :desc).each_with_object({}) do |page, issues|
          result = check_content_accessibility(page.body)

          issues[page.id] = result.merge(
            title: page.title,
            published: page.published?,
            updated_at: page.updated_at&.iso8601 || "",
            url: polymorphic_path([context, page]),
            edit_url: "#{polymorphic_path([context, page])}/edit"
          )
        end
      end
    end
  end
end
