namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    puts `dress_code config/styleguide.yml`
  end

  desc "Compile css assets."
  task :generate do
    raise 'the new way to compile sass is with `npm run compile-sass`. FYI, it uses libsass and is much faster'
  end

end
