group :test do
  gem 'testingbot', require: false
  gem 'testbot', github: 'smeredith0506/testbot', branch: 'master', ref: '47fbf057ab40f8a6e24b1ae780c3f1a176621892'
  gem 'simplecov', '0.9.2', require: false
    gem 'docile', '1.1.3', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'bluecloth', '2.2.0' # for generating api docs
    gem 'redcarpet', '3.0.0', require: false
    gem 'github-markdown', '0.6.8', require: false
  gem 'bullet_instructure', '4.0.3', require: 'bullet'
  gem 'mocha', github: 'maneframe/mocha', ref: 'bb8813fbb4cc589d7c58073d93983722d61b6919', require: false
    gem 'metaclass', '0.0.2', require: false
  gem 'thin', '1.6.3'
    gem 'eventmachine', '1.0.4', require: false

  gem 'rspec', '3.2.0'
  gem 'rspec-rails', '3.2.0'
  gem 'rspec-legacy_formatters', '1.0.0'
  gem 'rspec-collection_matchers', '1.1.2'

  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'

  gem 'once-ler', '0.0.15'

  gem 'sequel', '4.5.0', require: false
  gem 'selenium-webdriver', '2.43.0'
    gem 'childprocess', '0.5.0', require: false
    gem 'websocket', '1.0.7', require: false
  gem 'test_after_commit', '0.4.0'
  gem 'test-unit', '~> 3.0', require: false, platform: :ruby_22
  gem 'webmock', '1.16.1', require: false
    gem 'addressable', '2.3.5', require: false
    gem 'crack', '0.4.1', require: false
  gem 'yard', '0.8.7.6'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.6.3'
end
