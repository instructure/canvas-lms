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
    if self.respond_to? :submittable_object
      submittable_override = self.submittable_object&.planner_override_for(user)
      return submittable_override if submittable_override
    end

    if self.association(:planner_overrides).loaded?
      self.planner_overrides.find{|po| po.user_id == user.id && po.workflow_state != 'deleted'}
    else
      self.planner_overrides.where(user_id: user).where.not(workflow_state: 'deleted').take
    end
  end

  class Bookmarker
    class Bookmark < Array
      attr_writer :descending

      def <=>(other)
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
    #   You can also pass in a hash with the association name as the key and column name as the value
    #   to order by the joined values:
    #   e.g. Plannable::Bookmarker.new(AssessmentRequest, true, {submission: {assignment: :due_at}}, :id)

    def initialize(model, descending, *columns)
      @model = model
      @descending = !!descending
      @columns = format_columns(columns)
    end

    def format_columns(columns)
      columns.map do |col|
        col.is_a?(Array) ? col.map {|c| format_column(c)} : format_column(col)
      end
    end

    def format_column(col)
      return col if col.is_a?(Hash)
      col.to_s
    end

    # Retrieves the associated object or objects' attributes and values to be used
    # in the bookmark for comparison
    def associations_attributes(object, col)
      return unless col.is_a?(Hash)
      association = association_to_preload(col)
      item = object.class.eager_load(association).find(object.id)

      if association.is_a?(Hash)
        object_or_array = associated_object(item, association)
      elsif association.is_a?(Symbol)
        object_or_array = item.send(association)
      end

      if object_or_array.is_a? ActiveRecord::Associations::CollectionProxy
        association_pairs = object_or_array.collect { |o| [o.id, o.attributes] }
        pairs = [association, Hash[association_pairs]]
      else
        pairs = [association, object_or_array.attributes]
      end

      Hash[*pairs.flatten(1)]
    end

    # Loops through our association array (e.g. [:submission, :assignment, :course]) and grabs the
    # deepest associated object (e.g. `course` in this example)
    def associated_object(item, association)
      result = item
      association_array(association).each do |relation|
        result = result.send(relation)
      end
      result
    end

    # Turns an association hash into an array to be used for accessing the deepest
    # associated object, eg:
    #   {submission: {assignment: :course}} => [:submission, :assignment, :course]
    def association_array(obj)
      assoc = []
      obj.each_pair do |key, value|
        assoc << key
        assoc << value.is_a?(Hash) ? association_array(value) : value
      end
      assoc.flatten
    end

    # Gets the association from a hash or single nested hash to use for preloading
    # e.g. {submission: :cached_due_date} => :submission
    # or   {submission: {assignment: :due_at}} => {submission: :assignment}
    # or   {submission: {assignment: {course: id}}} => {submission: {assignment: :course}}
    def association_to_preload(col)
      result = {}
      col.each_pair do |key, value|
        return key if value.is_a?(Symbol)
        result[key] = value.is_a?(Hash) ? association_to_preload(value) : value
      end
      result
    end

    # Retrieves the value from the association if the column specified calls for it
    # e.g. for an assessment request object with a column specified as {submission: {assignment: :due_at}}, fetch
    # the value of the due_at column for the assignment that's associated through the submission for the
    # assessment request
    def association_value(object, col)
      return unless col.is_a?(Hash)
      _table, column = associated_table_column(col)
      associations_attributes(object, col).values.flat_map {|h| h.slice(column).values}
    end

    # Grabs the value to use for the bookmark & comparison
    def column_value(object, col)
      if col.is_a?(Array)
        object.attributes.values_at(*col).compact.first # coalesce nulls
      elsif col.is_a?(Hash)
        association_value(object, col).compact.first
      else
        object.attributes[col]
      end
    end

    def bookmark_for(object)
      bookmark = Bookmark.new
      bookmark.descending = @descending
      @columns.each do |col|
        val = column_value(object, col)
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

    # Gets the object or object's associated column name to be used in the SQL query
    def column_name(col)
      return associated_table_column_name(col) if col.is_a?(Hash)
      "#{@model.table_name}.#{col}"
    end

    # Joins the associated table & column together as a string to be used in a SQL query
    def associated_table_column_name(col)
      table, column = associated_table_column(col)
      table_name = Object.const_defined?(table.to_s.classify) ? table.to_s.classify.constantize.quoted_table_name : table.to_s
      [table_name, column].join(".")
    end

    # Finds the relevant table & column name when a hash is passed by checking if
    # the hash specifies a direct or nested (i.e. the hash's value is also a hash) association
    # returns an array of [table, column]
    def associated_table_column(col)
      return col.to_s unless col.is_a?(Hash)
      col.values.first.is_a?(Hash) ? col.values.first.first : col.first
    end

    def column_order(col_name)
      if col_name.is_a?(Array)
        order = "COALESCE(#{col_name.map{|c| column_name(c)}.join(', ')})"
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
        (column.is_a?(Array) ? "COALESCE(#{column.map{|c| column_name(c)}.join(', ')})" : column_name(column))
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
