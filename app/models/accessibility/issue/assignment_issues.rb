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
    module AssignmentIssues
      def generate_assignment_issues
        context.assignments.active.order(updated_at: :desc).each_with_object({}) do |assignment, issues|
          result = check_content_accessibility(assignment.description)

          issues[assignment.id] = result.merge(
            title: assignment.title,
            published: assignment.published?,
            updated_at: assignment.updated_at&.iso8601 || "",
            url: polymorphic_path([context, assignment]),
            edit_url: "#{polymorphic_path([context, assignment])}/edit"
          )
        end
      end
    end
  end
end
