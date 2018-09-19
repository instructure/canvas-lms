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

module Plannable
  ACTIVE_WORKFLOW_STATES = ['active', 'published'].freeze

  def self.included(base)
    base.class_eval do
      has_many :planner_overrides, as: :plannable
      after_save :update_associated_planner_overrides
      before_save :check_if_associated_planner_overrides_need_updating
      scope :available_to_planner, -> { where(workflow_state: ACTIVE_WORKFLOW_STATES) }
    end
  end

  def update_associated_planner_overrides_later
    send_later(:update_associated_planner_overrides) if @associated_planner_items_need_updating != false
  end

  def update_associated_planner_overrides
    PlannerOverride.update_for(self) if @associated_planner_items_need_updating
  end

  def check_if_associated_planner_overrides_need_updating
    @associated_planner_items_need_updating = false
    return if self.new_record?
    return if self.respond_to?(:context_type) && !PlannerOverride::CONTENT_TYPES.include?(self.context_type)
    @associated_planner_items_need_updating = true if self.try(:workflow_state_changed?) || self.workflow_state == 'deleted'
  end

  def planner_override_for(user)
    if self.association(:planner_overrides).loaded?
      self.planner_overrides.find{|po| po.user_id == user.id && po.workflow_state != 'deleted'}
    else
      self.planner_overrides.where(user_id: user).where.not(workflow_state: 'deleted').take
    end
  end

  class Bookmarker
    class Bookmark < Array
      attr_writer :descending

      def <=>(obj)
        val = super
        val *= -1 if @descending
        val
      end
    end
    #   mostly copy-pasted version of SimpleBookmarker
    #   ***
    #   Now you can add some hackyness to your life by passing in an array for some sweet coalescing action
    #   as well as the ability to reverse order
    #   e.g. Plannable::Bookmarker.new(Assignment, true, [:due_at, :created_at], :id)

    def initialize(model, descending, *columns)
      @model = model
      @descending = !!descending
      @columns = columns.map{|c| c.is_a?(Array) ? c.map(&:to_s) : c.to_s}
    end

    def bookmark_for(object)
      bookmark = Bookmark.new
      bookmark.descending = @descending
      @columns.each do |col|
        val = col.is_a?(Array) ?
          object.attributes.values_at(*col).compact.first : # coalesce nulls
          object.attributes[col]
        val = val.utc.strftime("%Y-%m-%d %H:%M:%S.%6N") if val.respond_to?(:strftime)
        bookmark << val
      end
      bookmark
    end

    TYPE_MAP = {
      string: -> (val) { val.is_a?(String) },
      integer: -> (val) { val.is_a?(Integer) },
      datetime: -> (val) { val.is_a?(String) && !!(DateTime.parse(val) rescue false) }
    }.freeze

    def validate(bookmark)
      bookmark.is_a?(Array) &&
        bookmark.size == @columns.size &&
        @columns.each.with_index.all? do |columns, i|
          columns = [columns] unless columns.is_a?(Array)
          columns.all? do |col|
            col = @model.columns_hash[col]
            if col
              type = TYPE_MAP[col.type]
              nullable = col.null
              type && (nullable && bookmark[i].nil? || type.call(bookmark[i]))
            else
              true
            end
          end
        end
    end

    def restrict_scope(scope, pager)
      if (bookmark = pager.current_bookmark)
        scope = scope.where(*comparison(bookmark))
      end
      scope.except(:order).order(order_by)
    end

    def order_by
      @order_by ||= Arel.sql(@columns.map { |col| column_order(col) }.join(', '))
    end

    def column_order(col_name)
      if col_name.is_a?(Array)
        order = "COALESCE(#{col_name.map{|c| "#{@model.table_name}.#{c}"}.join(", ")})"
      else
        order = column_comparand(col_name)
        if @model.columns_hash[col_name].null
          order = "#{column_comparand(col_name, '=')} IS NULL, #{order}"
        end
      end
      order += " DESC" if @descending
      order
    end

    def column_comparand(column, comparator = '>', placeholder = nil)
      col_name = placeholder ||
        (column.is_a?(Array) ?
        "COALESCE(#{column.map{|c| "#{@model.table_name}.#{c}"}.join(", ")})" :
        "#{@model.table_name}.#{column}")
      if comparator != "=" && type_for_column(column) == :string
        col_name = BookmarkedCollection.best_unicode_collation_key(col_name)
      end
      col_name
    end

    def column_comparison(column, comparator, value)
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
        if !column.is_a?(Array) && @model.columns_hash[column].null && comparator != '='
          # our sort order wants "NULL > ?" to be universally true for non-NULL
          # values (we already handle NULL values above). but it is false in
          # SQL, so we need to include "column IS NULL" with > or >=
          sql = "(#{sql} OR #{column_comparand(column, '=')} IS NULL)"
        end
        [sql, value]
      end
    end

    def type_for_column(col)
      col = col.first if col.is_a?(Array)
      @model.columns_hash[col]&.type
    end

    # Generate a sql comparison like so:
    #
    #   a > ?
    #   OR a = ? AND b > ?
    #   OR a = ? AND b = ? AND c > ?
    #
    # Technically there's an extra check in the actual result (for index
    # happiness), but it's logically equivalent to the example above
    def comparison(bookmark)
      top_clauses = []
      args = []
      visited = []
      pairs = @columns.zip(bookmark)
      comparator = @descending ? "<" : ">"
      while pairs.present?
        col, val = pairs.shift
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
      return [sql, *args]
    end
  end
end
