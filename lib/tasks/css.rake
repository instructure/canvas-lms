# frozen_string_literal: true

namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    if ENV.fetch("RAILS_ENV", "development") == "development"
      # python2 --version outputs to stderr, while python3 to stdout.......
      python_version = `#{Pygments::Popen.new.find_python_binary} --version 2>&1` rescue nil
      python_version ||= "???"

      unless /^Python 2/.match?(python_version.strip)
        next warn <<~TEXT
          Generating the CSS styleguide requires Python 2, but you have #{python_version}.

          If you already have a Python 2 installation, make sure it is available
          in your PATH under the name of "python2". If the name of the
          interpreter is different, adjust it in the following environment
          variable:

              PYGMENTS_RB_PYTHON=custom-python-interpreter

        TEXT
      end
    end

    puts "--> creating styleguide"
    system("bin/dress_code config/styleguide.yml")
    raise "error running dress_code" unless $?.success?
  end

  task :compile do
    require "action_view/helpers"
    require "canvas/cdn/revved_asset_urls"
    require "brandable_css"
    ActionView::Base.include(Canvas::Cdn::RevvedAssetUrls)
    BrandableCSS.save_default_files!
    system("yarn run build:css")
    raise "error running brandable_css" unless $?.success?
  end
end
