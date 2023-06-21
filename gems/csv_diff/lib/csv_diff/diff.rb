# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# rubocop:disable Rails/SquishedSQLHeredocs Rails isn't in this gem
module CsvDiff
  # We need to know which key(s) comprise the id, to properly detect deletes
  # vs updates. Other than that, we don't need to care what the data is, just
  # whether it's changed, so we just compare it as a byte array.
  class Diff
    def initialize(key_fields)
      @key_fields = Array(key_fields).map(&:to_s)
      @db_file = Tempfile.new(["csv_diff", ".sqlite3"])
      @db = SQLite3::Database.new(@db_file.path)
      @row_count = 0
      setup_database
    end

    def generate(previous_csv, current_csv, options = {})
      # have to read the first lines, so that CSV reads the headers
      row_previous = previous_csv.shift
      row_current = current_csv.shift

      check_headers(previous_csv, current_csv)
      canonical_headers = current_csv.headers.compact
      setup_output(canonical_headers)

      @db.transaction do
        insert("previous", row_previous, previous_csv, canonical_headers) if row_previous
        insert("current", row_current, current_csv, canonical_headers) if row_current
      end

      find_updates
      if options[:deletes]
        find_deletes(canonical_headers, options[:deletes])
      end

      @output.close
      io = @output_file.tap(&:rewind)
      if options[:return_count]
        { file_io: io, row_count: @row_count }
      else
        io
      end
    end

    protected

    def insert(table, row1, csv, header_order)
      add = lambda do |row|
        # We need to turn this row into an array of known order, so that fields
        # are guaranteed to be in the same order from both csvs.
        key = Marshal.dump(row.fields(*@key_fields))
        fields = row.fields(*header_order)
        data = Marshal.dump(fields)
        @db.execute("insert or replace into #{table} (key, data) values (?, ?)", [key, data])
      end

      add.call(row1)
      csv.each { |row| add.call(row) }
    end

    def find_updates
      # find both creates and updates where the pk is the same
      @db.execute(<<~SQL) do |(data)|
        select current.data from current
        left join previous on previous.key = current.key
        where current.data <> previous.data or previous.key is null
      SQL
        row = Marshal.load(data) # rubocop:disable Security/MarshalLoad
        @row_count += 1
        @output << row
      end
    end

    def find_deletes(headers, cb)
      @db.execute(<<~SQL) do |(data)|
        select previous.data from previous
        left join current on previous.key = current.key
        where current.key is null
      SQL
        row = CSV::Row.new(headers, Marshal.load(data)) # rubocop:disable Security/MarshalLoad
        # Allow the caller to munge the row to indicate deletion.
        cb.call(row)
        @row_count += 1
        @output << row
      end
    end

    def check_headers(a, b)
      unless a.headers && b.headers
        raise(CsvDiff::Failure, "CSVs given must have headers enabled, pass :headers => true to CSV constructor")
      end

      if a.headers.compact.sort != b.headers.compact.sort
        raise(CsvDiff::Failure, "CSV headers do not match, cannot diff")
      end

      unless a.headers.intersect?(@key_fields)
        raise(CsvDiff::Failure, "At least one primary key field must be present")
      end
    end

    def setup_database
      @db.execute("create table previous (key blob primary key, data blob)")
      @db.execute("create table current  (key blob primary key, data blob)")
    end

    def setup_output(headers)
      @output_file = Tempfile.new(["csv_diff", ".csv"])
      @output = CSV.open(@output_file,
                         "wb",
                         headers:)
      @output << headers
    end
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
