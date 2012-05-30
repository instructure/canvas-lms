# 1.9 has a built-in equivalent to fastercsv
if RUBY_VERSION > "1.9."
  # make an alias for CSV, which has replaced FasterCSV
  require 'csv'
  FasterCSV = CSV
else
  require 'fastercsv'
end
