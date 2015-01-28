# Copyright (C) 2014 Instructure, Inc.
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
    def self.bookmark_for(tool_proxy)
      tool_proxy.name || ''
    end

    def self.validate(bookmark)
      bookmark.is_a?(String)
    end

    def self.restrict_scope(scope, pager)
      if pager.current_bookmark
        name = pager.current_bookmark
        comparison = (pager.include_bookmark ? ">=" : ">")
        scope = scope.where(
          "name #{comparison} ?",
          name)
      end
      scope.order(:name)
    end
  end
end