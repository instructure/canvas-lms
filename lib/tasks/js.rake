# frozen_string_literal: true

require 'json'

namespace :js do
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
