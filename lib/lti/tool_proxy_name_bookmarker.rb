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
    def self.bookmark_for(tool_proxy)
      [(tool_proxy.name || '').downcase, tool_proxy.id]
    end

    def self.validate(bookmark)
      bookmark.is_a?(Array) && bookmark.size == 2 &&
        bookmark[0].is_a?(String) &&
        bookmark[1].is_a?(Integer)
    end

    def self.restrict_scope(scope, pager)
      name_collation_key = BookmarkedCollection.best_unicode_collation_key('lti_tool_proxies.name')
      placeholder_collation_key = BookmarkedCollection.best_unicode_collation_key('?')
      if pager.current_bookmark
        bookmark = pager.current_bookmark
        comparison = (pager.include_bookmark ? ">=" : ">")
        scope = scope.where(
          " (#{name_collation_key} = #{placeholder_collation_key} AND lti_tool_proxies.id #{comparison} ?) "\
          "OR #{name_collation_key} #{comparison} #{placeholder_collation_key}",
          bookmark[0], bookmark[1], bookmark[0])
      end
      scope.order(name_collation_key, :id)
    end
  end
end
