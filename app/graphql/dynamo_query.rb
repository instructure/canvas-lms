# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

##
# = Paginated Dynamo Queries
#
# Returning an instance of +DynamoQuery+ in a GraphQL resolver allows
# pagination to work for dynamo queries.
#
# NOTE: The current "Connection" implementation is awful. There is no way to
# disable the backwards pagination arguments (last/before). There is some
# ongoing work on Connections
# (https://github.com/rmosolgo/graphql-ruby/issues/1359).
#
# Since Dynamo only supports paging in one direction, we shouldn't include
# "after"/"last" arguments on these connections, but avoiding that in the
# current codebase is difficult.  Passing "after"/"last" will essentially be a
# no-op on dynamo connections.
class DynamoQuery
  attr_reader :partition_key, :sort_key

  def initialize(db,
                 table,
                 partition_key:,
                 key_condition_expression:,
                 expression_attribute_values:,
                 value:,
                 sort_key:,
                 scan_index_forward: true)
    @db = db
    @table = table
    @partition_key = partition_key
    @partition_value = value
    @sort_key = sort_key
    @scan_index_forward = scan_index_forward
    @key_condition_expression = +"#{partition_key} = :id"
    @key_condition_expression << " AND #{key_condition_expression}" if key_condition_expression
    @expression_attribute_values = expression_attribute_values.merge(":id" => value)
  end

  def limit(limit)
    @limit = limit
    self
  end

  def after(sort_cursor)
    @exclusive_start_key = if sort_cursor
                             {
                               @partition_key => @partition_value,
                               @sort_key => sort_cursor,
                             }
                           else
                             nil
                           end
    self
  end

  def each(&)
    query.items.each(&)
  end

  def map(&)
    each.map(&)
  end

  def first
    query.items.first
  end

  def last
    query.items.last
  end

  def query
    return @query if defined? @query

    params = {
      table_name: @table,
      key_condition_expression: @key_condition_expression,
      expression_attribute_values: @expression_attribute_values,
      scan_index_forward: @scan_index_forward,
    }
    params[:limit] = @limit if @limit
    params[:exclusive_start_key] = @exclusive_start_key if @exclusive_start_key
    @query = @db.query(params)
  end
end
