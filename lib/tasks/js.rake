# frozen_string_literal: true

require "json"

namespace :js do
  desc "Build development webpack js"
  task :webpack_development do
    puts "--> Building DEVELOPMENT webpack bundles"
    system "yarn run webpack-development"
    raise "Error running js:webpack_development: \nABORTING" if $?.exitstatus != 0
  end

  desc "Build production webpack js"
  task :webpack_production do
    puts "--> Building PRODUCTION webpack bundles"
    system "yarn run webpack-production"
    raise "Error running js:webpack_production: \nABORTING" if $?.exitstatus != 0
  end

  desc "Ensure up-to-date node environment"
  task :yarn_install do
    puts "node is: #{`node -v`.strip} (#{`which node`.strip})"

    # --production=false so that it still installs devDependencies as they are
    # needed for post-installation steps (like wsrun)
    #
    #  see https://classic.yarnpkg.com/en/docs/cli/install#toc-yarn-install-production-true-false
    yarnopts = "--frozen-lockfile --production=false"

    system "yarn install #{yarnopts} || yarn install #{yarnopts} --network-concurrency 1"
    unless $?.success?
      raise "error running yarn install"
    end
  end

  desc "Revision static assets"
  task :gulp_rev do
    system "yarn run gulp rev"

    unless $?.success?
      raise "error running gulp rev"
    end
  end
end
