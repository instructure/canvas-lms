module CsvDiff
  # We need to know which key(s) comprise the id, to properly detect deletes
  # vs updates. Other than that, we don't need to care what the data is, just
  # whether it's changed, so we just compare it as a byte array.
  class Diff
    def initialize(key_fields)
      @key_fields = Array(key_fields).map(&:to_s)
      @db_file = Tempfile.new(['csv_diff', '.sqlite3'])
      @db = SQLite3::Database.new(@db_file.path)
      setup_database
    end

    def generate(previous_csv, current_csv, options = {})
      # have to read the first lines, so that CSV reads the headers
      row_previous = previous_csv.shift
      row_current = current_csv.shift

      check_headers(previous_csv, current_csv)
      setup_output(current_csv.headers)

      @db.transaction do
        insert("previous", row_previous, previous_csv, current_csv.headers)
        insert("current", row_current, current_csv, nil)
      end

      find_updates
      if options[:deletes]
        find_deletes(current_csv.headers, options[:deletes])
      end

      @output.close
      @output_file.tap(&:rewind)
    end

    protected

    def insert(table, row1, csv, header_order)
      add = ->(row) {
        # We need to turn this row into an array of known order, so that fields
        # are guaranteed to be in the same order from both csvs.
        key = Marshal.dump(row.fields(*@key_fields))
        fields = if header_order
          row.fields(*header_order)
        else
          row.fields
        end
        data = Marshal.dump(fields)
        @db.execute("insert or replace into #{table} (key, data) values (?, ?)", [key, data])
      }

      add.(row1)
      csv.each { |row| add.(row) }
    end

    def find_updates
      # find both creates and updates where the pk is the same
      @db.execute(<<-SQL) do |(data)|
            select current.data from current
            left join previous on previous.key = current.key
            where current.data <> previous.data or previous.key is null
            SQL
        row = Marshal.load(data)
        @output << row
      end
    end

    def find_deletes(headers, cb)
      @db.execute(<<-SQL) do |(data)|
            select previous.data from previous
            left join current on previous.key = current.key
            where current.key is null
            SQL
        row = CSV::Row.new(headers, Marshal.load(data))
        # Allow the caller to munge the row to indicate deletion.
        cb.(row)
        @output << row
      end
    end

    def check_headers(a, b)
      unless a.headers && b.headers
        raise(CsvDiff::Failure, "CSVs given must have headers enabled, pass :headers => true to CSV constructor")
      end

      if a.headers.sort != b.headers.sort
        raise(CsvDiff::Failure, "CSV headers do not match, cannot diff")
      end

      if (a.headers & @key_fields).empty?
        raise(CsvDiff::Failure, "At least one primary key field must be present")
      end
    end

    def setup_database
      @db.execute("create table previous (key blob primary key, data blob)")
      @db.execute("create table current  (key blob primary key, data blob)")
    end

    def setup_output(headers)
      @output_file = Tempfile.new(['csv_diff', '.csv'])
      @output = CSV.open(@output_file, 'wb',
                         headers: headers)
      @output << headers
    end
  end
end
