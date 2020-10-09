namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    if ENV.fetch('RAILS_ENV', 'development') == 'development'
      # python2 --version outputs to stderr, while python3 to stdout.......
      python_version = `#{Pygments::Popen.new.find_python_binary} --version 2>&1` rescue nil
      python_version ||= '???'

      unless python_version.strip =~ /^Python 2/
        next warn <<~MESSAGE
          Generating the CSS styleguide requires Python 2, but you have #{python_version}.

          If you already have a Python 2 installation, make sure it is available
          in your PATH under the name of "python2". If the name of the
          interpreter is different, adjust it in the following environment
          variable:

              PYGMENTS_RB_PYTHON=custom-python-interpreter

        MESSAGE
      end
    end

    puts "--> creating styleguide"
    system('bin/dress_code config/styleguide.yml')
    fail "error running dress_code" unless $?.success?
  end

  task :compile do
    # try to get a conection to the database so we can do the brand_configs:write below
    require 'config/environment' rescue nil
    require 'config/initializers/plugin_symlinks'
    require 'config/initializers/revved_asset_urls'
    require 'lib/brandable_css'
    puts "--> Starting: 'css:compile'"
    time = Benchmark.realtime do
      if (BrandConfig.table_exists? rescue false)
        Rake::Task['brand_configs:write'].invoke
      else
        puts "--> no DB connection, skipping generation of brand_config files"
      end
      BrandableCSS.save_default_files!
      system('yarn run build:css')
      fail "error running brandable_css" unless $?.success?
    end
    puts "--> Finished: 'css:compile' in #{time}"
  end
end
