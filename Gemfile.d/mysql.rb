group :mysql do
  if CANVAS_RAILS3
    gem 'mysql2', '0.3.15'
  else
    gem 'mysql2', '0.2.18'
  end
end
