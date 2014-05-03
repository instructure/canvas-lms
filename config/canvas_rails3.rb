# You can enable the not-yet-complete Rails3 support by either defining a
# CANVAS_RAILS3 env var, or create an empty RAILS3 file in the canvas config dir
if ENV['CANVAS_RAILS3']
  CANVAS_RAILS3 = ENV['CANVAS_RAILS3'] != '0'
else
  CANVAS_RAILS3 = File.exist?(File.expand_path("../RAILS3", __FILE__))
end
CANVAS_RAILS2 = !CANVAS_RAILS3
