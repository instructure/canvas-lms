# You can enable the Rails 4 support by either defining a
# CANVAS_RAILS4=1 env var, or create an empty RAILS4 file in the canvas config dir
if !defined?(CANVAS_RAILS3)
  if ENV['CANVAS_RAILS4']
    CANVAS_RAILS3 = ENV['CANVAS_RAILS4'] != '1'
  else
    CANVAS_RAILS3 = !File.exist?(File.expand_path("../RAILS4", __FILE__))
  end
end
