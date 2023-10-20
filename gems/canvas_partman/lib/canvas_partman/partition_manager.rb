# frozen_string_literal: true

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

require "canvas_partman/partition_manager/by_date"
require "canvas_partman/partition_manager/by_id"
require "active_record/pg_extensions"

module CanvasPartman
  class PartitionManager
    class << self
      def create(base_class)
        unless base_class < Concerns::Partitioned
          raise ArgumentError, <<~TEXT
            PartitionManager can only work on models that are Partitioned.
            See CanvasPartman::Concerns::Partitioned.
          TEXT
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

    # Check that the current partition, and n future partitions exist
    #
    # @param [Integer] advance
    #   The number of partitions to check in advance
    def partitions_created?(_advance = 1)
      raise NotImplementedError
    end

    # Prune old partitions
    #
    # @param [Integer] number_to_keep
    #   The number of partitions to keep (excluding the current partition)
    def prune_partitions(_number_to_keep = 6); end

    # Create a new partition table.
    #
    # @param [Time/Integer] value
    #   The time or sequencial value to use in generating the table name.
    #
    # @param [Boolean] graceful
    #   Do nothing if the partition table already exists.
    #
    # @return [String]
    #   The name of the newly created partition table.
    def create_partition(value, graceful: false)
      partition_table = generate_name_for_partition(value)

      return if graceful && partition_exists?(partition_table)

      constraint_check = generate_check_constraint(value)

      with_statement_timeout do
        base_class.connection.transaction do
          execute(<<~SQL.squish)
            CREATE TABLE #{base_class.connection.quote_table_name(partition_table)} (
              LIKE #{base_class.quoted_table_name} INCLUDING ALL,
              CHECK (#{constraint_check})
            ) INHERITS (#{base_class.quoted_table_name})
          SQL

          # copy foreign keys, since INCLUDING ALL won't bring them along
          base_class.connection.foreign_keys(base_class.table_name).each do |foreign_key|
            base_class.connection.add_foreign_key partition_table, foreign_key.to_table, **foreign_key.options.except(:name)
          end

          CanvasPartman.after_create_callback.call(base_class, partition_table)
        end
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
      drop_partition_table(partition_table)
    end

    def with_statement_timeout(timeout_override: nil, &block)
      tv = timeout_override || ::CanvasPartman.timeout_value
      base_class.connection.with_statement_timeout(tv.to_f, &block)
    end

    protected

    def drop_partition_constraints(table_name)
      base_class.connection.foreign_keys(table_name).each do |fk|
        with_statement_timeout do
          base_class.connection.remove_foreign_key table_name, name: fk.name
        end
      end
    end

    def drop_partition_table(table_name)
      drop_partition_constraints(table_name)
      with_statement_timeout do
        base_class.connection.drop_table(table_name)
      end
    end

    def initialize(base_class)
      raise NotImplementedError if instance_of?(PartitionManager)

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
