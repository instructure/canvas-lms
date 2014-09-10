group :redis do
  gem 'redis-store', '1.1.4'
  gem 'redis', '3.1.0'
  gem 'redis-rails', CANVAS_RAILS3 ? '3.2.4' : '4.0.0'
  gem 'redis-scripting', '1.0.1'
end
