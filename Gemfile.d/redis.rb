group :redis do
  if CANVAS_RAILS4_2
    gem 'redis-rails', '4.0.0'
  else
    gem 'redis-rails', '5.0.1'
  end

  gem 'redis-store', '1.1.4', github: 'ccutrer/redis-store', ref: '72db36c56c6563fc65f213dcf8a1b77ddd22d1bb'
  gem 'redis', '3.3.1'
  gem 'redis-scripting', '1.0.1'
end
