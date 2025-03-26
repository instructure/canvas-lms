# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
  def resource_link_model(context: nil, course: nil, overrides: {})
    return Lti::ResourceLink.find_by!(resource_link_uuid: overrides[:resource_link_uuid]) if overrides.key?(:resource_link_uuid)

    course ||= Course.create!(name: "Course")
    context ||= Assignment.create!(course:, name: "Assignment")

    params = {
      context:,
      context_external_tool: overrides.fetch(:with_context_external_tool) do |_|
        external_tool_model(context: course, opts: overrides.fetch(:context_external_tool, {}))
      end,
      url: overrides.fetch(:url, "http://www.example.com/launch")
    }

    Lti::ResourceLink.create!(params)
  end
end
