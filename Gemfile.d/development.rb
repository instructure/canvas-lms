group :development do
  gem 'colorize', '0.8.1', require: false
  gem 'letter_opener', '1.4.1'
  gem 'spring', '2.0.0'
  gem 'spring-commands-rspec', '1.0.4'

  # Option to DISABLE_RUBY_DEBUGGING is helpful IDE-based debugging.
  # The ruby debug gems conflict with the IDE-based debugger gem.
  # Set this option in your dev environment to disable.
  unless ENV['DISABLE_RUBY_DEBUGGING']
    gem 'byebug', '9.0.6', platform: :mri
  end
end
