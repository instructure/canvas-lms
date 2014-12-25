group :test do
  gem 'testingbot', :require => false
  gem 'testbot', :github => 'smeredith0506/testbot', :branch => 'master', :ref => '47fbf057ab40f8a6e24b1ae780c3f1a176621892'
  gem 'simplecov', '0.8.2', :require => false
    gem 'docile', '1.1.3'
  gem 'simplecov-rcov', '0.2.3', :require => false
  gem 'bluecloth', '2.2.0' # for generating api docs
    gem 'redcarpet', '3.0.0'
  gem 'bullet_instructure', '4.0.3', :require => 'bullet'
  gem 'mocha', github: 'eac/mocha', :branch => 'eac/alias_method_fix', :ref => 'bb8813fbb4cc589d7c58073d93983722d61b6919', :require => false
    gem 'metaclass', '0.0.2'
  gem 'thin', '1.6.3'
    gem 'eventmachine', '1.0.4'

  gem 'rspec', '3.1.0'
  gem 'rspec-rails', '3.1.0'
  gem 'rspec-legacy_formatters', '1.0.0'
  gem 'rspec-collection_matchers', '1.1.2'
  gem 'once-ler', '0.0.15'

  gem 'sequel', '4.5.0', :require => false
  gem 'selenium-webdriver', '2.43.0'
    gem 'childprocess', '0.5.0'
    gem 'websocket', '1.0.7'
  gem 'test_after_commit', '0.4.0'
  gem 'webmock', '1.16.1', :require => false
    gem 'addressable', '2.3.5'
    gem 'crack', '0.4.1'
  gem 'yard', '0.8.0'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.6.3'
end
