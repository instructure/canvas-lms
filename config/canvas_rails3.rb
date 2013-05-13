# You can enable the not-yet-complete Rails3 support by either defining a
# CANVAS_RAILS3 env var, or create an empty RAILS3 file in the canvas RAILS_ROOT dir
CANVAS_RAILS3 = !!ENV['CANVAS_RAILS3'] || File.exist?(File.expand_path("../../RAILS3", __FILE__))
