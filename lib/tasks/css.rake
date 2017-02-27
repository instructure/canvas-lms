namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    system('bin/dress_code config/styleguide.yml')
    raise "error running dress_code" unless $?.success?
  end

  task :compile do
    require 'lib/brandable_css'
    puts "--> Starting: 'compile css (including custom brands)'"
    time = Benchmark.realtime { BrandableCSS.compile_all! }
    BrandableCSS.save_default_json!
    BrandableCSS.save_default_js!
    puts "--> Finished: 'compile css (including custom brands)' in #{time}"
  end
end
