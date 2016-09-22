# You can enable the Rails 5.0 support by either defining a
# CANVAS_RAILS5=1 env var, or create an empty RAILS5 file in the canvas config dir
if !defined?(CANVAS_RAILS4_2)
  if ENV['CANVAS_RAILS5']
    CANVAS_RAILS4_2 = ENV['CANVAS_RAILS5'] != '1'
  else
    CANVAS_RAILS4_2 = !File.exist?(File.expand_path("../RAILS5", __FILE__))
  end
end
