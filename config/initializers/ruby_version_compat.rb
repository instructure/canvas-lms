# 1.9 has a built-in equivalent to fastercsv
if RUBY_VERSION > "1.9."
  # make an alias for CSV, which has replaced FasterCSV
  require 'csv'
  FasterCSV = CSV
  # we still depend on the syck YAML for delayed jobs serialization
  require 'yaml'
  YAML::ENGINE.yamler = 'syck'
else
  require 'fastercsv'
end
