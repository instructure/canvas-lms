# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module Lti
  module ToolProxyNameBookmarker
    extend NameBookmarkerBase

    def self.bookmark_for(tool_proxy)
      bookmark_for_name_and_id(tool_proxy.name, tool_proxy.id)
    end

    def self.restrict_scope(scope, pager)
      restrict_scope_by_name_and_id_fields(
        scope:,
        pager:,
        name_field: "lti_tool_proxies.name",
        id_field: "lti_tool_proxies.id"
      )
    end
  end
end
