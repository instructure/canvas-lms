# lib/icons.rake

require 'lib/brandable_css'

namespace :icons do
  task :compile do
    puts "Compiling icons..."
    puts %x(bundle exec fontcustom compile --force)
    puts "Compiling stylesheets..."
    BrandableCSS.compile_all!
    puts "Compiling styleguide..."
    puts %x(bundle exec rake css:styleguide)
  end
end