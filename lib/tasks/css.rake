# frozen_string_literal: true

namespace :css do
  desc "Generate styleguide"
  task :styleguide do
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
