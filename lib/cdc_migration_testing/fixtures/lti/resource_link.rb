# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module CdcFixtures
  def self.create_resource_link
    resource_link_uuid = SecureRandom.uuid
    lookup_uuid = SecureRandom.uuid

    Lti::ResourceLink.new(
      id: 1,
      resource_link_uuid:,
      context_external_tool_id: 1,
      workflow_state: "active",
      root_account_id: 1,
      context_id: 1,
      context_type: "Course",
      custom: {},
      lookup_uuid:
    )
  end
end
