# You can enable the Rails 4.2 support by either defining a
# CANVAS_RAILS4_2=1 env var, or create an empty RAILS4_2 file in the canvas config dir
if !defined?(CANVAS_RAILS4_0)
  if ENV['CANVAS_RAILS4_2']
    CANVAS_RAILS4_0 = ENV['CANVAS_RAILS4_2'] != '1'
  else
    CANVAS_RAILS4_0 = !File.exist?(File.expand_path("../RAILS4_2", __FILE__))
  end
end
