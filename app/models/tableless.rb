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

# allows you to have models that do not have database tables
# concept pulled from the comments of this page:
# http://stackoverflow.com/questions/937429/activerecordbase-without-table-rails
class Tableless < ActiveRecord::Base
  class << self
    def load_schema; end

    def columns(&block)
      if block
        @columns_block = block
      else
        if @columns.nil? && !@columns_block.nil?
          @columns = []
          @columns_block.call
        end
        @columns ||= []
      end
    end

    def columns_hash
      @columns_hash ||= columns.index_by(&:name)
    end

    def column(name, sql_type = nil, default = nil)
      cast_type = connection.send(:lookup_cast_type, sql_type.to_s)
      type_metadata = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
        sql_type: sql_type.to_s,
        type: cast_type.type,
        limit: cast_type.limit,
        precision: cast_type.precision,
        scale: cast_type.scale
      )
      args = [name.to_s, default, type_metadata, sql_type.to_s]
      columns << ActiveRecord::ConnectionAdapters::Column.new(*args)
    end

    def table_exists?
      false
    end
  end

  # Override the save method to prevent exceptions.
  def save(validate = true)
    validate ? valid? : true
  end

  def self.sharded_primary_key?
    false
  end

  def self.find_by_sql(*)
    []
  end

  def self.count_by_sql(*)
    0
  end

  def self.delete_all(*); end

  def self.update_all(*); end

  def self.execute_simple_calculation(*); end

  def self.execute_grouped_calculation(*); end
end
