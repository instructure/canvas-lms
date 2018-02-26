#
# Copyright (C) 2017 - present Instructure, Inc.
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

module ExternalToolsSpecHelper
  # Public: Create a new valid LTI tool for the given course.
  #
  # course - The course to create the tool for.
  #
  # Returns a valid ExternalTool.
  def new_valid_tool(course, overrides = {})
    tool = course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
    )
    tool.url = overrides.fetch(:url, "http://www.example.com/basic_lti")
    tool.resource_selection = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :selection_width => 400,
      :selection_height => 400
    }
    tool.settings['post_only'] = true if overrides[:post_only]
    tool.save!
    tool
  end
end
