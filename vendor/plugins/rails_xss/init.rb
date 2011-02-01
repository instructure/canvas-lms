unless $gems_rake_task
  if Rails::VERSION::MAJOR >= 3
    $stderr.puts "You don't need to install rails_xss as a plugin for Rails 3 and after."
  elsif Rails::VERSION::MAJOR <= 2 && Rails::VERSION::MINOR <= 3 && Rails::VERSION::TINY <= 7
    $stderr.puts "rails_xss requires Rails 2.3.8 or later. Please upgrade to enable automatic HTML safety."
  else
    require 'rails_xss'
  end
end
