namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    Bundler.clean_system('bin/dress_code config/styleguide.yml')
    raise "error running dress_code" unless $?.success?
  end
end
