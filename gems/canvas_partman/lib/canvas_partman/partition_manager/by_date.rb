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
    class ByDate < PartitionManager
      def create_initial_partitions(advance_partitions = 1)
        min = base_class.minimum(base_class.partitioning_field).try(:utc)
        max = base_class.maximum(base_class.partitioning_field).try(:utc)

        if min && max
          while min < max
            create_partition(min)
            min += 1.send(base_class.partitioning_interval)
          end
          create_partition(min)
        end

        ensure_partitions(advance_partitions)
      end

      def migrate_data_to_partitions(batch_size: 1000, timeout: nil)
        start_time = Time.now
        loop do
          return false if timeout && (start_time + timeout) < Time.now

          id_dates = base_class.from("ONLY #{base_class.quoted_table_name}")
                               .order(base_class.partitioning_field)
                               .limit(batch_size)
                               .pluck(:id, base_class.partitioning_field)
          break if id_dates.empty?

          id_dates.group_by { |_id, date| generate_name_for_partition(date) }.each do |partition_table, part_id_dates|
            base_class.connection.execute(<<~SQL.squish)
              WITH x AS (
                DELETE FROM ONLY #{base_class.quoted_table_name}
                WHERE id IN (#{part_id_dates.map(&:first).join(", ")})
                RETURNING *
              ) INSERT INTO #{base_class.connection.quote_table_name(partition_table)} SELECT * FROM x
            SQL
          end
        end
        true
      end

      def ensure_partitions(advance = 1)
        ensure_or_check_partitions(advance, true)
      end

      def partitions_created?(advance = 1)
        ensure_or_check_partitions(advance, false)
      end

      def ensure_or_check_partitions(advance, create_partitions)
        current = Time.now.utc.send(:"beginning_of_#{base_class.partitioning_interval.to_s.singularize}")
        (advance + 1).times do
          unless partition_exists?(current)
            if create_partitions
              create_partition(current)
            else
              return false
            end
          end
          current += 1.send(base_class.partitioning_interval)
        end
        true
      end

      def prune_partitions(number_to_keep = 6)
        min_to_keep = Time.now.utc.send(:"beginning_of_#{base_class.partitioning_interval.to_s.singularize}")
        # on 5/1, we want to drop 10/1
        # (keeping 11, 12, 1, 2, 3, and 4 - 6 months of data)
        min_to_keep -= number_to_keep.send(base_class.partitioning_interval)

        partition_tables.each do |table|
          partition_date = date_from_partition_name(table)
          drop_partition_table(table) if partition_date < min_to_keep
        end
      end

      def partition_exists?(date_or_name)
        table_name = if date_or_name.is_a?(Time)
                       generate_name_for_partition(date_or_name)
                     else
                       date_or_name
                     end
        super(table_name)
      end

      def partition_tables
        super.sort_by { |t| date_from_partition_name(t) }
      end

      protected

      def table_regex
        @table_regex ||= case base_class.partitioning_interval
                         when :weeks
                           /^#{Regexp.escape(base_class.table_name)}_(?<year>\d{4,})_(?<week>\d{2,})$/
                         when :months
                           /^#{Regexp.escape(base_class.table_name)}_(?<year>\d{4,})_(?<month>\d{1,2})$/
                         when :years
                           /^#{Regexp.escape(base_class.table_name)}_(?<year>\d{4,})$/
                         end
      end

      def generate_check_constraint(date)
        constraint_range = generate_date_constraint_range(date).map { |d| d.to_fs(:db) }

        <<~SQL.squish
          #{base_class.partitioning_field} >= TIMESTAMP '#{constraint_range[0]}'
          AND
          #{base_class.partitioning_field} < TIMESTAMP '#{constraint_range[1]}'
        SQL
      end

      def date_from_partition_name(name)
        match = table_regex.match(name)
        return nil unless match

        if base_class.partitioning_interval == :weeks
          Time.utc(match[:year]).beginning_of_week + (match[:week].to_i - 1).weeks
        else
          Time.utc(*match[1..])
        end
      end

      def generate_date_constraint_range(date)
        case base_class.partitioning_interval
        when :weeks
          [
            0.weeks.from_now(date).beginning_of_week,
            1.week.from_now(date).beginning_of_week
          ]
        when :months
          [
            0.months.from_now(date).beginning_of_month,
            1.month.from_now(date).beginning_of_month
          ]
        when :years
          [
            0.years.from_now(date).beginning_of_year,
            1.year.from_now(date).beginning_of_year
          ]
        end
      end
    end
  end
end
