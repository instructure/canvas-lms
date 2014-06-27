# lib/icons.rake

namespace :icons do
  task :compile do
    puts "Compiling icons..."
    puts %x(bundle exec fontcustom compile)
  end
end