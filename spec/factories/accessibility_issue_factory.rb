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
module Factories
  def accessibility_issue_model(opts = {})
    opts[:course] ||= course_model
    opts[:accessibility_resource_scan] ||= accessibility_resource_scan_model(course: opts[:course])

    # Handle syllabus scans specially
    if opts[:accessibility_resource_scan].is_syllabus?
      opts[:is_syllabus] = true
      # Don't set context for syllabus issues
    else
      opts[:context] ||= opts[:accessibility_resource_scan].context
    end

    opts[:rule_type] ||= Accessibility::Rules::ImgAltRule.id

    AccessibilityIssue.create!(opts)
  end
end
