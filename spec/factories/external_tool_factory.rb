# frozen_string_literal: true

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
#

module Factories
  BASE_ATTRS = {
    name: "a",
    url: "http://google.com",
    consumer_key: "12345",
    shared_secret: "secret"
  }.freeze

  def external_tool_model(context: nil, opts: {})
    context ||= course_model
    context.context_external_tools.create(
      BASE_ATTRS.merge(opts)
    )
  end

  def external_tool_1_3_model(context: nil, opts: {}, developer_key: nil)
    developer_key ||= DeveloperKey.create!
    opts = { developer_key_id: developer_key.id, lti_version: "1.3", url: "https://example.com/1_3/launch", domain: "example.com" }.merge(opts)
    external_tool_model(context:, opts:)
  end
end
