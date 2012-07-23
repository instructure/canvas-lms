# Require any additional compass plugins here.
require 'bootstrap-sass'

project_type = :rails
project_path = RAILS_ROOT if defined?(RAILS_ROOT)
# Set this to the root of your project when deployed:
http_path = "/"
css_dir = "public/stylesheets/compiled"
cache_dir = "/tmp/sassc"
sass_dir = "app/stylesheets"
images_dir = "public/images"
javascripts_dir = "public/javascripts"
# To enable relative paths to assets via compass helper functions. Uncomment:
# relative_assets = true
http_images_path = "/images"
http_stylesheets_path = "/stylesheets"
http_javascripts_path = "/javascripts"
output_style = (environment == :production) ? :compressed : :nested