# Set this to the root of your project when deployed:
http_path = "/"
# css_dir is set dynamically in MultiVariantCompassCompiler#compile_all
sass_dir = "app/stylesheets"
images_dir = "public/images"
javascripts_dir = "public/javascripts"
# To enable relative paths to assets via compass helper functions. Uncomment:
# relative_assets = true
http_images_path = "/images"
http_stylesheets_path = "/stylesheets"
http_javascripts_path = "/javascripts"
output_style = (environment == :production) ? :compressed : :nested



# Run all of our outputed css through autoprefixer.
# it will remove any browser prefixes that we don't need and
# add any that we do need.

# HEY DEVELOPER: When you write your css, just write it prefix-free and
# let autoprefixer take care of the prefixes for you :)
require 'autoprefixer-rails'
require File.expand_path('../../lib/browser', __FILE__)

supported_browsers = Browser.minimum_browsers.map do |browser|
  "#{browser.browser.sub("Internet Explorer", "Explorer")} >= #{browser.version}"
end

on_stylesheet_saved do |file|
  css = File.read(file)
  File.open(file, 'w') do |io|
    io << AutoprefixerRails.process(css, browsers: supported_browsers, cascade: false)
  end
end
