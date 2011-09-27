# 1.9 has a built-in equivalent to fastercsv
if RUBY_VERSION > "1.9."
  require 'csv'
  FasterCSV = CSV
else
  require 'fastercsv'
end
