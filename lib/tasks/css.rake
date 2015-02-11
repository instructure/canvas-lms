namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    puts `dress_code config/styleguide.yml`
  end
end
