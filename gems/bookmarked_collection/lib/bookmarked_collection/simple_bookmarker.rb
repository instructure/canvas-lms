#
# Copyright (C) 2013 Instructure, Inc.
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

# A general purpose bookmarker for most use cases (sorting by one or more
# columns in ascending order). Uses best_unicode_collation_key for string
# comparisons. Currently only supports strings and integers, but could be
# trivially extended to support others (see TYPE_MAP)
#
# Example:
#
#   GroupBookmarker = BookmarkedCollection::SimpleBookmarker.new(Group, :name, :id)
#
#   ...
#
#   bookmarked_collection = BookmarkedCollection.wrap(GroupBookmarker, @current_user.groups)
#   Api.paginate bookmarked_collection, ...
#
module BookmarkedCollection
  class SimpleBookmarker
    def initialize(model, *columns)
      @model = model
      @columns = columns.map(&:to_s)
    end

    def bookmark_for(object)
      object.attributes.values_at *@columns
    end

    TYPE_MAP = {
      string: String,
      integer: Integer
    }

    def validate(bookmark)
      bookmark.is_a?(Array) &&
      bookmark.size == @columns.size &&
      @columns.each.with_index.all? do |col, i|
        type = TYPE_MAP[@model.columns_hash[col].type]
        type && bookmark[i].is_a?(type)
      end
    end

    def restrict_scope(scope, pager)
      if bookmark = pager.current_bookmark
        scope = scope.where(*comparison(bookmark, pager.include_bookmark))
      end
      scope.order order_by
    end

    def order_by
      @order_by ||= @columns.map { |col| column_comparand(col) }.join(', ')
    end

    def column_comparand(col_name, placeholder = nil)
      col = @model.columns_hash[col_name]
      col_name = placeholder || "#{@model.table_name}.#{col_name}"
      if col.type == :string
        col_name = BookmarkedCollection.best_unicode_collation_key(col_name)
      end
      col_name
    end

    def column_comparison(column, comparator = ">")
      "#{column_comparand(column)} #{comparator} #{column_comparand(column, '?')}"
    end

    # Generate a sql comparison like so:
    #
    #   a > ?
    #   OR a = ? AND b > ?
    #   OR a = ? AND b = ? AND c > ?
    #
    # If include_bookmark = true, the very last ">" becomes a ">="
    #
    # Technically there's an extra check in the actual result (for index
    # happiness), but it's logically equivalent to the example above
    def comparison(bookmark, include_bookmark)
      sql = comparison_sql % {last_comparator: (include_bookmark ? ">=" : ">")}
      [sql, *comparison_args(bookmark)]
    end

    # DRY alert: needs to match placeholder order (see comparison_sql)
    def comparison_args(bookmark)
      values = bookmark.dup
      args = []
      visited = []
      while values.present?
        visited.push values.shift
        args.concat visited
      end
      args << bookmark.first # for index happiness
    end

    # DRY alert: needs to match argument order (see comparison_args)
    def comparison_sql
      @comparison_sql ||= begin
        parts = []
        visited = []
        columns = @columns.dup
        comparator = ">"
        while columns.present?
          col = columns.shift
          comparator = "%{last_comparator}" if columns.empty?
          part = ""
          visited.each{ |v| part << "#{@model.table_name}.#{v} = ? AND " }
          part << column_comparison(col, comparator)
          parts << part
          visited << col
        end
        "(" << parts.join(" OR ") << ") AND " <<
          column_comparison(@columns.first, ">=") # for index happiness
      end
    end
  end
end
