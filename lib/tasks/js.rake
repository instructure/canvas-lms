require 'json'

namespace :js do

  desc "Build client_apps"
  task :build_client_apps do
    require 'config/initializers/client_app_symlinks'

    Dir.glob('./client_apps/*/').each do |app_dir|
      app_name = File.basename(app_dir)

      Dir.chdir(app_dir) do
        puts "Building client app '#{app_name}'"

        if File.exists?('./package.json')
          output = `yarn install`
          unless $?.exitstatus == 0
            puts "INSTALL FAILURE:\n#{output}"
            raise "Package installation failure for client app #{app_name}"
          end
        end

        puts "\tRunning 'yarn run build'..."
        output = `./script/build`
        unless $?.exitstatus == 0
          puts "BUILD FAILURE:\n#{output}"
          raise "Build script failed for client app #{app_name}"
        end

        puts "Client app '#{app_name}' was built successfully."
      end
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
    system "yarn install --frozen-lockfile"
    unless $?.success?
      raise 'error running yarn install'
    end
  end

end
