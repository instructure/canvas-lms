#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'canvas_partman/partition_manager/by_date'
require 'canvas_partman/partition_manager/by_id'

module CanvasPartman
  class PartitionManager
    class << self
      def create(base_class)
        unless base_class < Concerns::Partitioned
          raise ArgumentError, <<-ERROR
PartitionManager can only work on models that are Partitioned.
See CanvasPartman::Concerns::Partitioned.
          ERROR
        end

        const_get(base_class.partitioning_strategy.to_s.classify).new(base_class)
      end
    end

    attr_reader :base_class

    # Create partitions to hold existing data in a non-partitioned
    # table, and n future partitions
    #
    # @param [Integer] advance
    #   The number of partitions to create in advance
    def create_initial_partitions(_advance = 1)
      raise NotImplementedError
    end

    # Ensure the current partition, and n future partitions exist
    #
    # @param [Integer] advance
    #   The number of partitions to create in advance
    def ensure_partitions(_advance = 1)
      raise NotImplementedError
    end

    # Prune old partitions
    #
    # @param [Integer] number_to_keep
    #   The number of partitions to keep (excluding the current partition)
    def prune_partitions(_number_to_keep = 6)
    end

    # Create a new partition table.
    #
    # @param [Integer] graceful
    #   Do nothing if the partition table already exists.
    #
    # @return [String]
    #  The name of the newly created partition table.
    def create_partition(value, graceful: false)
      partition_table = generate_name_for_partition(value)

      if graceful == true
        return if partition_exists?(partition_table)
      end

      constraint_check = generate_check_constraint(value)

      execute(<<SQL)
      CREATE TABLE #{base_class.connection.quote_table_name(partition_table)} (
        LIKE #{base_class.quoted_table_name} INCLUDING ALL,
        CHECK (#{constraint_check})
      ) INHERITS (#{base_class.quoted_table_name})
SQL

      # copy foreign keys, since INCLUDING ALL won't bring them along
      base_class.connection.foreign_keys(base_class.table_name).each do |foreign_key|
        base_class.connection.add_foreign_key partition_table, foreign_key.to_table, foreign_key.options.except(:name)
      end

      partition_table
    end

    def partition_tables
      base_class.connection.tables.grep(table_regex)
    end

    def partition_exists?(table_name)
      base_class.connection.table_exists?(table_name)
    end

    def drop_partition(value)
      partition_table = generate_name_for_partition(value)

      base_class.connection.drop_table(partition_table)
    end

    protected

    def initialize(base_class)
      raise NotImplementedError if self.class == PartitionManager
      @base_class = base_class
    end

    def table_regex
      raise NotImplementedError
    end

    def generate_check_constraint(_value)
      raise NotImplementedError
    end

    def generate_name_for_partition(value)
      attr = Arel::Attributes::Attribute.new(nil, base_class.partitioning_field)

      attributes = {}
      attributes[attr] = value

      base_class.infer_partition_table_name(attributes)
    end

    def execute(*args)
      base_class.connection.execute(*args)
    end
  end
end
