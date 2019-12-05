#
# Copyright (C) 2013 - present Instructure, Inc.
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
  class Bookmark < Array
    def <=>(other)
      length = [self.size, other.size].min
      length.times do |i|
        if self[i].nil? && other[i].nil?
          next
        elsif self[i].nil?
          return 1
        elsif other[i].nil?
          return -1
        else
          return self[i] <=> other[i]
        end
      end
    end
  end
  class SimpleBookmarker
    def initialize(model, *columns)
      @model = model
      @columns = columns.map(&:to_s)
    end

    def bookmark_for(object)
      Bookmark.new object.attributes.values_at(*@columns)
    end

    TYPE_MAP = {
      string: -> (val) { val.is_a?(String) },
      integer: -> (val) { val.is_a?(Integer) },
      datetime: -> (val) { val.is_a?(DateTime) || val.is_a?(Time) || val.is_a?(String) && !!(DateTime.parse(val) rescue false) }
    }

    def validate(bookmark)
      bookmark.is_a?(Array) &&
      bookmark.size == @columns.size &&
      @columns.each.with_index.all? do |col, i|
        type = TYPE_MAP[@model.columns_hash[col].type]
        nullable = @model.columns_hash[col].null
        type && (nullable && bookmark[i].nil? || type.(bookmark[i]))
      end
    end

    def restrict_scope(scope, pager)
      if bookmark = pager.current_bookmark
        scope = scope.where(*comparison(bookmark, pager.include_bookmark))
      end
      scope.order order_by
    end

    def order_by
      @order_by ||= Arel.sql(@columns.map { |col| column_order(col) }.join(', '))
    end

    def column_order(col_name)
      order = column_comparand(col_name)
      if @model.columns_hash[col_name].null
        order = "#{column_comparand(col_name, '=')} IS NULL, #{order}"
      end
      order
    end

    def column_comparand(col_name, comparator = '>', placeholder = nil)
      col = @model.columns_hash[col_name]
      col_name = placeholder || "#{@model.table_name}.#{col_name}"
      if col.type == :string && comparator != "="
        col_name = BookmarkedCollection.best_unicode_collation_key(col_name)
      end
      col_name
    end

    def column_comparison(column, comparator, value)
      # comparator is only ever '>', '>=', or '='. never '<' or '<='
      if value.nil? && comparator == ">"
        # sorting by a nullable column puts nulls last, so for our sort order
        # 'column > NULL' is universally false
        ["0=1"]
      elsif value.nil?
        # likewise only NULL values in column satisfy 'column = NULL' and
        # 'column >= NULL'
        ["#{column_comparand(column, '=')} IS NULL"]
      else
        sql = "#{column_comparand(column, comparator)} #{comparator} #{column_comparand(column, comparator, '?')}"
        if @model.columns_hash[column].null && comparator != '='
          # our sort order wants "NULL > ?" to be universally true for non-NULL
          # values (we already handle NULL values above). but it is false in
          # SQL, so we need to include "column IS NULL" with > or >=
          sql = "(#{sql} OR #{column_comparand(column, '=')} IS NULL)"
        end
        [sql, value]
      end
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
      top_clauses = []
      args = []
      visited = []
      pairs = @columns.zip(bookmark)
      comparator = ">"
      while pairs.present?
        col, val = pairs.shift
        comparator = ">=" if pairs.empty? && include_bookmark
        clauses = []
        visited.each do |c,v|
          clause, *clause_args = column_comparison(c, "=", v)
          clauses << clause
          args.concat(clause_args)
        end
        clause, *clause_args = column_comparison(col, comparator, val)
        clauses << clause
        top_clauses << clauses.join(" AND ")
        args.concat(clause_args)
        visited << [col, val]
      end
      sql = "(" << top_clauses.join(" OR ") << ")"
      # one additional clause for index happiness
      index_sql, *index_args = column_comparison(@columns.first, ">=", bookmark.first)
      sql = [sql, index_sql].join(" AND ")
      args.concat(index_args)
      return [sql, *args]
    end
  end
end
