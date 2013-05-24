if RUBY_VERSION < "1.9"
  require 'fastercsv'
else
  # 1.9 has a built-in equivalent to fastercsv
  # make an alias for CSV, which has replaced FasterCSV
  require 'csv'
  FasterCSV = CSV
end
