# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
# Updates a column in a table in bulk. This is useful when you have a large
# TSV file of new values for a column in a table and you want to update the
# table to populate the values. Example use from a rails console:
#
# log_filename = "bcu#{Time.now.iso8661}.log"
# Shard.with_each_shard(Shard.in_current_region, parallel: true) do
#   DataFixup::BulkColumnUpdater
#     .new(ContextExternalTool, :unified_tool_id, log_filename:)
#     .update_from_tsv!("cet_unified_tool_ids/#{Shard.current.id}.tsv")
# end
#
# Where example is a TSV file with two columns: `id` and a value for the
# `unified_tool_id` column for that row
#
# This is chunked in two ways:
# 1. The rows are written to a temporary table in chunks of INSERT_CHUNK_SIZE
# 2. The temporary table is flushed to the real table in chunks of
#    TRANSACTION_CHUNK_SIZE
# All values are written into a buffer, then chunked to be fed into the DB
module DataFixup
  class BulkColumnUpdater
    TRANSACTION_CHUNK_SIZE = 10_000
    INSERT_CHUNK_SIZE = 1_000

    attr_reader :model_class, :allow_nils, :allow_empty_strings, :column_name

    def initialize(model_class, column_name, log_filename: nil, allow_nils: false, allow_empty_strings: false)
      raise ArgumentError, "model_class not a class" unless model_class.is_a?(Class)
      raise ArgumentError, "model_class not a model" unless model_class < ActiveRecord::Base
      raise ArgumentError, "column_name not a string" unless [Symbol, String].include?(column_name.class)
      raise ArgumentError, "unknown column_name" unless model_class.column_names.include?(column_name.to_s)
      raise ArgumentError, "only supported for integer id columns" unless model_class.columns_hash["id"].type == :integer

      @model_class = model_class
      @column_name = column_name.to_s
      @log_filename = log_filename
      @allow_nils = allow_nils
      @allow_empty_strings = allow_empty_strings
    end

    # @param blk -- unary function, for backwards-compatibility with scripts.
    #   The argument passed to blk is a function. Call that function with an
    #   array of [id, value] tuples (to update multiple rows)
    # Example:
    #   DataFixup::BulkColumnUpdater.new(User, :name).update! do |fn|
    #     fn.call [[1, "Alice"], [2, "Bob"]]
    #   end
    # @return [Integer] number of rows updated
    def update!(&)
      @logger = Logger.new(@log_filename) if @log_filename
      @rows_buffer = []
      yield method(:add_to_rows_buffer!)
      flush_rows_buffer!
    rescue => e
      if @logger
        log "ERROR: #{e.inspect}"
        -1
      else
        raise
      end
    ensure
      @logger&.close
      @logger = nil
    end

    def log(line)
      @logger&.info "shard #{Shard.current.id}: #{line}"
    end

    # Load from a TSV file. The TSV file should have two columns: id and value.
    # No header.
    # To set a value to NULL, include a line with just the id, no tab or value,
    #   and use allow_nils in the constructor
    # To set a value to an empty string, include a line with the id and a tab
    #   but no value and use allow_empty_Strings in the constructor
    def update_from_tsv!(tsv_file, batch_size: 1000)
      File.open(tsv_file, "r") do |f|
        update! do |add_rows_fn|
          loop do
            lines = f.each_line.first(batch_size)
            break if lines.empty?

            rows = lines.map { parse_tsv_line(it) }
            add_rows_fn.call(rows)
          end
        end
      end
    end

    private

    def parse_tsv_line(line)
      # passing -1 to split to keep trailing empty strings
      # 123 -> ["123"]
      # 123\t -> ["123", ""]
      # 123\t\t -> ["123", "", ""]
      case line.chomp.split("\t", -1)
      in [id]
        [id, nil]
      in row
        row
      end
    end

    def quoted_column_name
      model_class.connection.quote_column_name(column_name)
    end

    def create_temp_table!
      if @temp_table_name
        raise ArgumentError, "Flush old temp table before creating new"
      end

      @temp_table_name = model_class.table_name[0..50] + "_#{SecureRandom.base36(10)}"
      # quote_table_name adds schema, which we don't want
      @quoted_temp_table_name = '"pg_temp".' + model_class.connection.quote_column_name(@temp_table_name)

      model_class.connection.create_table(
        "pg_temp.#{@temp_table_name}",
        temporary: true,
        id: model_class.columns_hash["id"].sql_type,
        options: "ON COMMIT DROP"
      ) do |t|
        t.column column_name, model_class.columns_hash[column_name].sql_type
      end

      log "Created temp table #{@temp_table_name}"
    end

    def quote(*)
      model_class.connection.quote(*)
    end

    def validate_rows!(rows)
      raise ArgumentError, "Invalid Rows: #{rows.inspect}" unless rows.is_a?(Array)

      rows.each do |row|
        unless row.is_a?(Array)
          raise ArgumentError, "Row not an array: #{row.inspect}"
        end
        unless row.length == 2
          raise ArgumentError, "Row should have two columns, has #{row.length}: #{row.inspect}"
        end
        unless row[0].to_i.to_s == row[0].to_s
          raise ArgumentError, "First column should be an integer: #{row.inspect}"
        end
        if row[1].nil? && !allow_nils
          raise ArgumentError, "Second column should not be nil: #{row.inspect}"
        end
        if row[1] == "" && !allow_empty_strings
          raise ArgumentError, "Second column should not be an empty string: #{row.inspect}"
        end
      end
    end

    def add_to_rows_buffer!(rows)
      validate_rows!(rows)
      @rows_buffer.concat(rows)
    end

    def flush_rows_buffer!
      n_written = 0

      @rows_buffer.each_slice(TRANSACTION_CHUNK_SIZE) do |transaction_chunk|
        model_class.transaction do
          create_temp_table!
          transaction_chunk.each_slice(INSERT_CHUNK_SIZE) do |insert_chunk|
            write_to_temp_table!(insert_chunk)
          end
          n_written += flush_temp_table!
        end
      end

      n_written
    end

    def write_to_temp_table!(rows)
      raise ArgumentError unless @quoted_temp_table_name

      sql_values = rows.map do |row|
        id, value = row
        "(#{quote(id)}, #{quote(value)})"
      end

      model_class.connection.execute(<<~SQL.squish)
        INSERT INTO #{@quoted_temp_table_name} (id, #{quoted_column_name})
        VALUES #{sql_values.join(",")}
      SQL

      log "Wrote #{rows.length} rows to temp table #{@quoted_temp_table_name}"
    end

    def flush_temp_table!
      raise ArgumentError unless @quoted_temp_table_name

      # take values we stored in the temp table and write them into the real
      # table
      result = model_class.connection.execute(<<~SQL.squish)
        UPDATE #{model_class.quoted_table_name} AS t
        SET #{quoted_column_name} = tt.#{quoted_column_name}
        FROM #{@quoted_temp_table_name} AS tt
        WHERE t.id = tt.id
      SQL
      log "Flush #{@quoted_temp_table_name} to #{model_class.quoted_table_name} complete: #{result.cmd_tuples} rows updated"

      result.cmd_tuples
    rescue
      log "ERROR! Flush to #{@quoted_temp_table_name} FAILED, abandoning temp table, these rows will be lost!"
      raise
    ensure
      @temp_table_name = nil
      @quoted_temp_table_name = nil
    end
  end
end
