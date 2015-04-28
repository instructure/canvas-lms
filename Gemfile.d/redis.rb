group :redis do
  gem 'redis-store', '1.1.4', github: 'ccutrer/redis-store', ref: '72db36c56c6563fc65f213dcf8a1b77ddd22d1bb'
  gem 'redis', '3.1.0'
  gem 'redis-rails', CANVAS_RAILS3 ? '3.2.4' : '4.0.0'
  gem 'redis-scripting', '1.0.1'
end
