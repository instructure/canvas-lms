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
  RESOURCE_TYPE_MAPPING = {
    wiki_page: :context,
    assignment: :context,
    attachment: :context
  }.freeze

  def accessibility_resource_scan_model(opts = {})
    opts[:course] ||= course_model

    normalized_opts = normalize_resource_context(opts)
    normalized_opts[:context] ||= wiki_page_model(course: normalized_opts[:course])

    AccessibilityResourceScan.create!(normalized_opts)
  end

  def normalize_resource_context(opts)
    resource_key = RESOURCE_TYPE_MAPPING.keys.find { |key| opts.key?(key) }

    return opts unless resource_key

    opts.except(resource_key).merge(context: opts[resource_key])
  end
end
