# You can disable the Rails3 support by either defining a
# CANVAS_RAILS3=0 env var, or create an empty RAILS2 file in the canvas config dir
if ENV['CANVAS_RAILS3']
  CANVAS_RAILS3 = ENV['CANVAS_RAILS3'] != '0'
else
  CANVAS_RAILS3 = !File.exist?(File.expand_path("../RAILS2", __FILE__))
end
CANVAS_RAILS2 = !CANVAS_RAILS3
