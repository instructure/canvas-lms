require 'csv'
require 'tempfile'

require 'sqlite3'

require "csv_diff/diff"
require "csv_diff/version"

module CsvDiff
  class Failure < RuntimeError
  end
end
