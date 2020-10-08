require 'json'

namespace :js do

  desc "Build client_apps"
  task :build_client_apps do
    Dir.glob("./client_apps/*/").each do |app_dir|
      Rake::Task['js:build_client_app'].invoke(File.basename(app_dir))
    end
  end

  desc "Build a specific client_app"
  task :build_client_app, [:app_name] do |t, app_name:|
    require 'config/initializers/client_app_symlinks'

    npm_install = ENV["COMPILE_ASSETS_NPM_INSTALL"] != "0"

    Dir.chdir("./client_apps/#{app_name}") do
      puts "Building client app '#{app_name}'"

      if npm_install && File.exists?('./package.json')
        output = system 'yarn install --pure-lockfile || yarn install --pure-lockfile --network-concurrency 1'
        unless $?.exitstatus == 0
          puts "INSTALL FAILURE:\n#{output}"
          raise "Package installation failure for client app #{app_name}"
        end
      end

      puts "\tRunning 'yarn run build'..."
      output = if File.exists?('./script/build')
        `./script/build`
      else
        `yarn run build`
      end

      unless $?.exitstatus == 0
        puts "BUILD FAILURE:\n#{output}"
        raise "Build script failed for client app #{app_name}"
      end

      puts "Client app '#{app_name}' was built successfully."
    end

    maintain_client_app_symlinks
  end
  desc "Build development webpack js"
  task :webpack_development do
    require 'config/initializers/plugin_symlinks'
    puts "--> Building DEVELOPMENT webpack bundles"
    system "yarn run webpack-development"
    raise "Error running js:webpack_development: \nABORTING" if $?.exitstatus != 0
  end

  desc "Build production webpack js"
  task :webpack_production do
    require 'config/initializers/plugin_symlinks'
    puts "--> Building PRODUCTION webpack bundles"
    system "yarn run webpack-production"
    raise "Error running js:webpack_production: \nABORTING" if $?.exitstatus != 0
  end

  desc "Ensure up-to-date node environment"
  task :yarn_install do
    puts "node is: #{`node -v`.strip} (#{`which node`.strip})"
    system 'yarn install --pure-lockfile || yarn install --pure-lockfile --network-concurrency 1'
    unless $?.success?
      raise 'error running yarn install'
    end
  end

  desc "Revision static assets"
  task :gulp_rev do
    system 'yarn run gulp rev'

    unless $?.success?
      raise 'error running gulp rev'
    end
  end
end
