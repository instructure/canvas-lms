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
    time = Benchmark.realtime do
      if (BrandConfig.table_exists? rescue false)
        Rake::Task['brand_configs:clean'].invoke
        Rake::Task['brand_configs:write'].invoke
      else
        puts "--> no DB connection, skipping generation of brand_config files"
      end
      BrandableCSS.save_default_files!
      BrandableCSS.compile_all!
    end
    puts "--> Finished: 'compile css (including custom brands)' in #{time}"
  end
end
