group :development do
  gem 'guard', '1.8.0'
  gem 'listen', '~>1.3' # pinned to fix guard error
  gem 'rb-inotify', '~>0.9.0', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  gem "letter_opener"
  gem 'spring', '1.1.3', :github => 'ccutrer/spring', :branch => 'reload_hang', :ref => 'a622f051501976cdbef452c9752c1af364c9ad26'
  gem 'spring-commands-rspec', '1.0.2'

  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.


  unless ENV['DISABLE_RUBY_DEBUGGING']
    gem 'byebug', '3.5.1', :platforms => [:ruby_20, :ruby_21, :ruby_22]
      gem 'columnize', '0.9.0', :platforms => [:ruby_20, :ruby_21, :ruby_22]
    gem 'debugger', '1.6.6', :platforms => :ruby_19
  end
end
