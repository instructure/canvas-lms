# You can disable the Rails 4.2 support by defining a
# CANVAS_RAILS4_2=0 env var
if !defined?(CANVAS_RAILS4_0)
  if ENV['CANVAS_RAILS4_2']
    CANVAS_RAILS4_0 = ENV['CANVAS_RAILS4_2'] == '0'
  else
    CANVAS_RAILS4_0 = false
  end
end
