gem 'newrelic_rpm'

group :development do
  gem 'capistrano', '3.2.1', require: false
  gem 'capistrano-rails',   '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  gem 'capistrano-canvas', :git => 'https://github.com/grahamb/capistrano-canvas.git', require: false
  gem 'capistrano-scm-copy', :git => 'https://github.com/grahamb/capistrano-scm-copy.git', require: false
end
