# frozen_string_literal: true

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
# comparisons (unless otherwise specified).
# Currently only supports strings, integers, and datetimes;
# could be trivially extended to support others (see TYPE_MAP)
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
# To not use best_unicode_collation_key, instead of a column symbol, pass in a hash with the column
# as a key and its value another hash containing {:skip_collation => true}

# Example:
#
#   CourseBookmarker = BookmarkedCollection::SimpleBookmarker.new(
#     Course, {:integration_id => {:skip_collation => true}}, :id)
#
# This way of passing in options can also be used to pass in column definitions in order to
# add ordering on custom select attributes (like those pulled from join tables)
#
# Example:
#
#   EnrollmentBookmarker = BookmarkedCollection::SimpleBookmarker.new(
#     Enrollment, {:sortable_name => {:type => :string, :null => false}}, :id)
#   ...
#   enrollment_scope = course.enrollments.joins(:user).select("enrollments.*, users.sortable_name AS sortable_name")
#   bookmarked_collection = BookmarkedCollection.wrap(EnrollmentBookmarker, enrollment_scope)

module BookmarkedCollection
  class Bookmark < Array
    def <=>(other)
      length = [size, other.size].min
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
    def initialize(model, *args)
      @model = model
      @initial_args = args
    end

    def load_definitions
      return if @column_definitions

      # apparently can't do this on intitialization because we sometimes create bookmarker objects before db is loaded
      @column_definitions = {}
      @columns = []
      @initial_args.each do |arg|
        if arg.is_a?(Hash)
          # allow us to sort on things that aren't actual columns
          arg.each do |col_name, definition|
            col_name = col_name.to_s
            @columns << col_name
            @column_definitions[col_name] = validate_definition(
              existing_column_definition(col_name).merge(definition).merge(custom: true)
            )
          end
        else
          col_name = arg.to_s
          @columns << col_name
          @column_definitions[col_name] = validate_definition(existing_column_definition(col_name))
        end
      end
    end

    def columns
      load_definitions
      @columns
    end

    def column_definitions
      load_definitions
      @column_definitions
    end

    def bookmark_for(object)
      Bookmark.new object.attributes.values_at(*columns)
    end

    TYPE_MAP = {
      string: ->(val) { val.is_a?(String) },
      integer: ->(val) { val.is_a?(Integer) },
      datetime: ->(val) { val.is_a?(DateTime) || val.is_a?(Time) || (val.is_a?(String) && !!(DateTime.parse(val) rescue false)) },
      float: ->(val) { val.is_a?(Float) }
    }.freeze

    def existing_column_definition(col_name)
      col = @model.columns_hash[col_name]
      col ? { type: col.type, null: col.null } : {}
    end

    def validate_definition(definition)
      raise "expected :type and :null to be specified" unless [:type, :null].all? { |k| definition.key?(k) }

      definition
    end

    def validate(bookmark)
      bookmark.is_a?(Array) &&
        bookmark.size == columns.size &&
        columns.each.with_index.all? do |col, i|
          type = TYPE_MAP[column_definitions[col][:type]]
          nullable = column_definitions[col][:null]
          type && ((nullable && bookmark[i].nil?) || type.call(bookmark[i]))
        end
    end

    def restrict_scope(scope, pager)
      if (bookmark = pager.current_bookmark)
        scope = scope.where(*comparison(bookmark, pager.include_bookmark))
      end
      scope.order order_by
    end

    def order_by
      @order_by ||= {}
      locale = defined?(Canvas::ICU) ? Canvas::ICU.locale_for_collation : :default
      @order_by[locale] ||= Arel.sql(columns.map { |col| column_order(col) }.join(", "))
    end

    def column_order(col_name)
      order = column_comparand(col_name)
      if column_definitions[col_name][:null]
        order = "#{column_comparand(col_name, "=")} IS NULL, #{order}"
      end
      order
    end

    def column_comparand(col_name, comparator = ">", placeholder = nil)
      definition = column_definitions[col_name]
      col_name = placeholder ||
                 (definition[:custom] ? col_name : "#{@model.table_name}.#{col_name}")
      if definition[:type] == :string && !definition[:skip_collation] && comparator != "="
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
        ["#{column_comparand(column, "=")} IS NULL"]
      else
        sql = "#{column_comparand(column, comparator)} #{comparator} #{column_comparand(column, comparator, "?")}"
        if column_definitions[column][:null] && comparator != "="
          # our sort order wants "NULL > ?" to be universally true for non-NULL
          # values (we already handle NULL values above). but it is false in
          # SQL, so we need to include "column IS NULL" with > or >=
          sql = "(#{sql} OR #{column_comparand(column, "=")} IS NULL)"
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
      pairs = columns.zip(bookmark)
      comparator = ">"
      while pairs.present?
        col, val = pairs.shift
        comparator = ">=" if pairs.empty? && include_bookmark
        clauses = []
        visited.each do |c, v|
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
      sql = "(" + top_clauses.join(" OR ") + ")"
      # one additional clause for index happiness
      index_sql, *index_args = column_comparison(columns.first, ">=", bookmark.first)
      sql = [sql, index_sql].join(" AND ")
      args.concat(index_args)
      [sql, *args]
    end
  end
end
