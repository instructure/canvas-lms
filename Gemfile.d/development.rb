group :development do
  gem 'guard', '1.8.0'
  gem 'listen', '~>1.3' # pinned to fix guard error
  gem 'rb-inotify', '~>0.9.0', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  if CANVAS_RAILS3
    gem "letter_opener"
  else
    gem "letter_opener", :git => 'git://github.com/cavi21/letter_opener.git'
  end

  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    gem 'byebug', '3.1.2', :platforms => [:ruby_20, :ruby_21]
    gem 'debugger', '1.6.6', :platforms => :ruby_19
  end
end
