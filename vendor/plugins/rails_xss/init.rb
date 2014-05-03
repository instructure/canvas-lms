unless $gems_rake_task
  if Rails::VERSION::MAJOR >= 3
    # XXX [RAILS3] We can remove vendor/plugins/rails_xss entirely once on rails 3.
  elsif Rails::VERSION::MAJOR <= 2 && Rails::VERSION::MINOR <= 3 && Rails::VERSION::TINY <= 7
    $stderr.puts "rails_xss requires Rails 2.3.8 or later. Please upgrade to enable automatic HTML safety."
  else
    require 'rails_xss'
  end
end
