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

# Base for bookmarkers for models that have a named and are to be sorted on by
# [name, id].  We use a collation key for the name as the first item of the
# bookmark to ensure consistency with the database collation (e.g. when merging
# bookmarks of different types)
module Lti
  module NameBookmarkerBase
    def bookmark_for(_model)
      raise "abstract"
    end

    def validate(bookmark)
      bookmark.is_a?(Array) && bookmark.size == 3 &&
        bookmark[0].is_a?(String) &&
        bookmark[1].is_a?(Integer) &&
        bookmark[2].is_a?(String)
    end

    def restrict_scope(_scope, _pager)
      raise "abstract"
    end

    private

    # Helpers to be used by implementations

    def bookmark_for_name_and_id(name, id)
      name ||= ""
      # first element is simply so that BookmarkedCollection.merge can sort items
      # in pure Ruby
      [Canvas::ICU.collation_key(name), id, name]
    end

    def restrict_scope_by_name_and_id_fields(
      scope:, pager:, name_field:, id_field:, order: true
    )
      name_collation_key = BookmarkedCollection.best_unicode_collation_key(name_field)

      if pager.current_bookmark
        placeholder_collation_key = BookmarkedCollection.best_unicode_collation_key("?")
        bookmark = pager.current_bookmark
        comparison = (pager.include_bookmark ? ">=" : ">")
        scope = scope.where(
          " (#{name_collation_key} = #{placeholder_collation_key} AND #{id_field} #{comparison} ?) " \
          "OR #{name_collation_key} #{comparison} #{placeholder_collation_key}",
          bookmark[2],
          bookmark[1],
          bookmark[2]
        )
      end

      scope = scope.order(name_collation_key, :id) if order
      scope
    end
  end
end
