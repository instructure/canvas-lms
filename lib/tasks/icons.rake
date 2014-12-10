# lib/icons.rake

namespace :icons do
  task :compile do
    puts "Compiling icons..."
    puts %x(bundle exec fontcustom compile --force)
    puts "Compiling stylesheets..."
    puts %x(bundle exec npm run compile-sass)    
    puts "Compiling styleguide..."
    puts %x(bundle exec rake css:styleguide)
  end
end