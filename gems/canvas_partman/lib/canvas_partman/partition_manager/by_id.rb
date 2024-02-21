# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module CanvasPartman
  class PartitionManager
    class ById < PartitionManager
      def create_initial_partitions(advance_partitions = 1)
        max_id = base_class.maximum(base_class.partitioning_field)
        return ensure_partitions(advance_partitions) if max_id.nil?

        (0..(max_id / base_class.partition_size) + advance_partitions).each do |index|
          create_partition(index * base_class.partition_size, graceful: true)
        end
      end

      def migrate_data_to_partitions(batch_size: 1000)
        loop do
          ids = base_class.from("ONLY #{base_class.quoted_table_name}")
                          .order(base_class.partitioning_field)
                          .limit(batch_size)
                          .pluck(:id, base_class.partitioning_field)
          break if ids.empty?

          partition = ids.first.last / base_class.partition_size
          partition_table = [base_class.table_name, partition].join("_")
          # make sure we're only moving rows for one partition at a time
          ids.select! { |(_id, partitioning_field)| partitioning_field / base_class.partition_size == partition }
          base_class.connection.execute(<<~SQL.squish)
            WITH x AS (
              DELETE FROM ONLY #{base_class.quoted_table_name}
              WHERE id IN (#{ids.map(&:first).join(", ")})
              RETURNING *
            ) INSERT INTO #{base_class.connection.quote_table_name(partition_table)} SELECT * FROM x
          SQL
        end
      end

      def ensure_partitions(advance = 1)
        ensure_or_check_partitions(advance, true)
      end

      def partitions_created?(advance = 1)
        ensure_or_check_partitions(advance, false)
      end

      def ensure_or_check_partitions(advance, create_partitions)
        empties = 0
        partitions = partition_tables

        current = if partitions.empty?
                    -1
                  else
                    partitions.last[base_class.table_name.length + 1..].to_i
                  end

        if partition_on_primary_key?
          partitions.reverse_each do |partition|
            break if empties >= advance
            break if base_class.from(base_class.connection.quote_table_name(partition)).exists?

            empties += 1
          end
        else
          id = maximum_foreign_id
          last_needed = id ? (id / base_class.partition_size) : -1
          # yes `empties` could be negative but that just means we'll make even more partitions to catch up
          empties = current - last_needed
        end

        while empties < advance
          current += 1
          if create_partitions
            create_partition(current * base_class.partition_size)
          else
            return false
          end
          empties += 1
        end
        true
      end

      def partition_tables
        super.sort_by { |t| t[base_class.table_name.length + 1..].to_i }
      end

      protected

      def partition_on_primary_key?
        base_class.partitioning_field.to_s == base_class.primary_key.to_s
      end

      def maximum_foreign_id
        reflection = base_class.reflections.detect { |_, r| r.belongs_to? && base_class.partitioning_field.to_s }.last
        klasses =
          if reflection.polymorphic?
            reflection.options[:polymorphic].map do |type|
              if type.is_a?(Hash)
                type.values.map { |v| v.constantize rescue nil }
              else
                type.to_s.classify.constantize rescue nil
              end
            end.flatten.compact
          else
            [reflection.klass]
          end
        klasses = klasses.map(&:base_class).uniq
        klasses.filter_map { |klass| klass.maximum(klass.primary_key) }.max
      end

      def table_regex
        @table_regex ||= /^#{Regexp.escape(base_class.table_name)}_(?<index>\d+)$/
      end

      def generate_check_constraint(id)
        index = id / base_class.partition_size
        column = base_class.connection.quote_column_name(base_class.partitioning_field)
        if index == 0
          "#{column} < #{base_class.partition_size}"
        else
          "#{column} >= #{index * base_class.partition_size} AND #{column} < #{(index + 1) * base_class.partition_size}"
        end
      end
    end
  end
end
