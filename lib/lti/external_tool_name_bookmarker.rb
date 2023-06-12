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
  module ExternalToolNameBookmarker
    extend NameBookmarkerBase

    def self.bookmark_for(external_tool)
      bookmark_for_name_and_id(external_tool.name, external_tool.id)
    end

    def self.restrict_scope(scope, pager)
      # Note -- order is apparently unnecessary here, it has already been done
      # by ContextExternalTools.all_tools_for()
      restrict_scope_by_name_and_id_fields(
        scope:,
        pager:,
        name_field: "context_external_tools.name",
        id_field: "context_external_tools.id",
        order: false
      )
    end
  end
end
