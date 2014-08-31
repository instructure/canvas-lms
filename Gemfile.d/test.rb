group :test do
  gem 'testbot', :github => 'smeredith0506/testbot'
  gem 'simplecov', '0.8.2', :require => false
    gem 'docile', '1.1.3'
  gem 'simplecov-rcov', '0.2.3', :require => false
  gem 'bluecloth', '2.0.10' # for generating api docs
    gem 'redcarpet', '3.0.0'
  gem 'bullet_instructure', '4.0.3', :require => 'bullet'
  if RUBY_VERSION >= '2.1'
    gem 'mocha', github: 'eac/mocha', :branch => 'eac/alias_method_fix', :ref => 'bb8813fbb4cc589d7c58073d93983722d61b6919', :require => false
      gem 'metaclass', '0.0.2'
  else
    gem 'mocha', '1.1.0', :require => false
      gem 'metaclass', '0.0.2'
  end
  gem 'thin', '1.5.1'
    if RUBY_VERSION >= '2.2'
      gem 'eventmachine', :github => 'eventmachine/eventmachine'
    else
      gem 'eventmachine', '1.0.3'
    end

  gem 'rspec', '2.99.0'
  gem 'rspec-rails', '2.99.0'
  gem 'once-ler', '0.0.13'

  gem 'sequel', '4.5.0', :require => false
  gem 'selenium-webdriver', '2.42.0'
    gem 'childprocess', '0.5.0'
    gem 'websocket', '1.0.7'
  gem 'webmock', '1.16.1', :require => false
    gem 'addressable', '2.3.5'
    gem 'crack', '0.4.1'
  gem 'yard', '0.8.0'
  gem 'yard-appendix', '>=0.1.8'
  gem 'timecop', '0.6.3'
end
