require 'lib/handlebars/handlebars'

namespace :jst do
  desc 'precompile handlebars templates from app/views/jst to public/javascripts/jst'
  task :compile do
    Handlebars.compile 'app/views/jst', 'public/javascripts/jst'
  end
end

