# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require 'pathname'
require 'yaml'
require 'open3'

module BrandableCSS
  APP_ROOT = defined?(Rails) && Rails.root || Pathname.pwd
  CONFIG = YAML.load_file(APP_ROOT.join('config/brandable_css.yml')).freeze
  BRANDABLE_VARIABLES = JSON.parse(File.read(APP_ROOT.join(CONFIG['paths']['brandable_variables_json']))).freeze
  MIGRATION_NAME = 'RegenerateBrandFilesBasedOnNewDefaults'.freeze

  use_compressed = (defined?(Rails) && Rails.env.production?) || (ENV['RAILS_ENV'] == 'production')
  SASS_STYLE = ENV['SASS_STYLE'] || ((use_compressed ? 'compressed' : 'nested')).freeze

  VARIABLE_HUMAN_NAMES = {
    "ic-brand-primary" => lambda { I18n.t("Primary Brand Color") },
    "ic-brand-font-color-dark" => lambda { I18n.t("Main Text Color") },
    "ic-link-color" => lambda { I18n.t("Link Color") },
    "ic-brand-button--primary-bgd" => lambda { I18n.t("Primary Button") },
    "ic-brand-button--primary-text" => lambda { I18n.t("Primary Button Text") },
    "ic-brand-button--secondary-bgd" => lambda { I18n.t("Secondary Button") },
    "ic-brand-button--secondary-text" => lambda { I18n.t("Secondary Button Text") },
    "ic-brand-global-nav-bgd" => lambda { I18n.t("Nav Background") },
    "ic-brand-global-nav-ic-icon-svg-fill" => lambda { I18n.t("Nav Icon") },
    "ic-brand-global-nav-ic-icon-svg-fill--active" => lambda { I18n.t("Nav Icon Active") },
    "ic-brand-global-nav-menu-item__text-color" => lambda { I18n.t("Nav Text") },
    "ic-brand-global-nav-menu-item__text-color--active" => lambda { I18n.t("Nav Text Active") },
    "ic-brand-global-nav-avatar-border" => lambda { I18n.t("Nav Avatar Border") },
    "ic-brand-global-nav-menu-item__badge-bgd" => lambda { I18n.t("Nav Badge") },
    "ic-brand-global-nav-menu-item__badge-text" => lambda { I18n.t("Nav Badge Text") },
    "ic-brand-global-nav-logo-bgd" => lambda { I18n.t("Nav Logo Background") },
    "ic-brand-header-image" => lambda { I18n.t("Nav Logo") },
    "ic-brand-mobile-global-nav-logo" => lambda { I18n.t("Responsive Global Nav Logo") },
    "ic-brand-watermark" => lambda { I18n.t("Watermark") },
    "ic-brand-watermark-opacity" => lambda { I18n.t("Watermark Opacity") },
    "ic-brand-favicon" => lambda { I18n.t("Favicon") },
    "ic-brand-apple-touch-icon" => lambda { I18n.t("Mobile Homescreen Icon") },
    "ic-brand-msapplication-tile-color" => lambda { I18n.t("Windows Tile Color") },
    "ic-brand-msapplication-tile-square" => lambda { I18n.t("Windows Tile: Square") },
    "ic-brand-msapplication-tile-wide" => lambda { I18n.t("Windows Tile: Wide") },
    "ic-brand-right-sidebar-logo" => lambda { I18n.t("Right Sidebar Logo") },
    "ic-brand-Login-body-bgd-color" => lambda { I18n.t("Background Color") },
    "ic-brand-Login-body-bgd-image" => lambda { I18n.t("Background Image") },
    "ic-brand-Login-body-bgd-shadow-color" => lambda { I18n.t("Body Shadow") },
    "ic-brand-Login-logo" => lambda { I18n.t("Login Logo") },
    "ic-brand-Login-Content-bgd-color" => lambda { I18n.t("Top Box Background") },
    "ic-brand-Login-Content-border-color" => lambda { I18n.t("Top Box Border") },
    "ic-brand-Login-Content-inner-bgd" => lambda { I18n.t("Inner Box Background") },
    "ic-brand-Login-Content-inner-border" => lambda { I18n.t("Inner Box Border") },
    "ic-brand-Login-Content-inner-body-bgd" => lambda { I18n.t("Form Background") },
    "ic-brand-Login-Content-inner-body-border" => lambda { I18n.t("Form Border") },
    "ic-brand-Login-Content-label-text-color" => lambda { I18n.t("Login Label") },
    "ic-brand-Login-Content-password-text-color" => lambda { I18n.t("Login Link Color") },
    "ic-brand-Login-footer-link-color" => lambda { I18n.t("Login Footer Link") },
    "ic-brand-Login-footer-link-color-hover" => lambda { I18n.t("Login Footer Link Hover") },
    "ic-brand-Login-instructure-logo" => lambda { I18n.t("Login Instructure Logo") }
  }.freeze

  GROUP_NAMES = {
    "global_branding" => lambda { I18n.t("Global Branding") },
    "global_navigation" => lambda { I18n.t("Global Navigation") },
    "watermarks" => lambda { I18n.t("Watermarks & Other Images") },
    "login" => lambda { I18n.t("Login Screen") }
  }.freeze

  HELPER_TEXTS = {
    "ic-brand-header-image" => lambda { I18n.t("Accepted formats: svg, png, jpg, gif") },
    "ic-brand-mobile-global-nav-logo" => lambda { I18n.t("Appears at the top of the global navigation tray that opens on mobile sized screens. display height: 48px. Accepted formats: svg, png, jpg, gif") },
    "ic-brand-watermark" => lambda { I18n.t("This image appears as a background watermark to your page. Accepted formats: png, svg, gif, jpeg") },
    "ic-brand-watermark-opacity" => lambda { I18n.t("Specify the transparency of the watermark background image.") },
    "ic-brand-favicon" => lambda { I18n.t("You can use a single 16x16, 32x32, 48x48 ico file.") },
    "ic-brand-apple-touch-icon" => lambda { I18n.t("The shortcut icon for iOS/Android devices. 180x180 png") },
    "ic-brand-msapplication-tile-square" => lambda { I18n.t("558x558 png, jpg, gif (1.8x the standard tile size, so it can be scaled up or down as needed)") },
    "ic-brand-msapplication-tile-wide" => lambda { I18n.t("558x270 png, jpg, gif") },
    "ic-brand-right-sidebar-logo" => lambda { I18n.t("A full-size logo that appears in the right sidebar on the Canvas dashboard. Ideal size is 360 x 140 pixels. Accepted formats: svg, png, jpeg, gif") },
    "ic-brand-Login-body-bgd-shadow-color" => lambda { I18n.t("accepted formats: hex, rgba, rgb, hsl") }
  }.freeze

  class << self
    def variables_map
      @variables_map ||= BRANDABLE_VARIABLES.each_with_object({}) do |variable_group, memo|
        variable_group['variables'].each { |variable| memo[variable['variable_name']] = variable }
      end.freeze
    end

    def variables_map_with_image_urls
      @variables_map_with_image_urls ||= variables_map.each_with_object({}) do |(key, config), memo|
        if config['type'] == 'image'
          memo[key] = config.merge('default' => ActionController::Base.helpers.image_url(config['default']))
        else
          memo[key] = config
        end
      end.freeze
    end

    def things_that_go_into_defaults_md5
      variables_map.each_with_object({}) do |(variable_name, config), memo|
        default = config['default']
        if config['type'] == 'image'
          # to make consistent md5s whether the cdn is enabled or not, don't include hostname in defaults
          default = ActionController::Base.helpers.image_path(default, host: '')
        end
        memo[variable_name] = default
      end.freeze
    end

    def migration_version
      # ActiveRecord usually uses integer timestamps to generate migration versions but any integer
      # will work, so we just use the result of stripping out the alphabetic characters from the md5
      default_variables_md5_without_migration_check.gsub(/[a-z]/, '').to_i.freeze
    end

    def check_if_we_need_to_create_a_db_migration
      path = ActiveRecord::Migrator.migrations_paths.first
      migrations = ActiveRecord::MigrationContext.new(path, ActiveRecord::SchemaMigration).migrations
      ['predeploy', 'postdeploy'].each do |pre_or_post|
        migration = migrations.find { |m| m.name == MIGRATION_NAME + pre_or_post.camelize }
        # they can't have the same id, so we just add 1 to the postdeploy one
        expected_version = (pre_or_post == 'predeploy') ? migration_version : (migration_version + 1)
        raise BrandConfigWithOutCompileAssets if expected_version == 66777721041301445917021322766375798443641
        raise DefaultMD5NotUpToDateError unless migration && migration.version == expected_version
      end
    end

    def skip_migration_check?
      # our canvas_rspec build doesn't even run `yarn install` or `gulp rev` so since
      # they are not expecting all the frontend assets to work, this check isn't useful
      Rails.env.test? && !Rails.root.join('public', 'dist', 'rev-manifest.json').exist?
    end

    def default_variables_md5
      @default_variables_md5 ||= begin
        check_if_we_need_to_create_a_db_migration unless skip_migration_check?
        default_variables_md5_without_migration_check
      end
    end

    def default_variables_md5_without_migration_check
      Digest::SHA256.hexdigest(things_that_go_into_defaults_md5.to_json).freeze
    end

    def handle_urls(value, config, css_urls)
      return value unless config['type'] == 'image' && css_urls
      "url('#{value}')" if value.present?
    end

    # gets the *effective* value for a brandable variable
    def brand_variable_value(variable_name, active_brand_config=nil, config_map=variables_map, css_urls=false)
      config = config_map[variable_name]
      explicit_value = active_brand_config && active_brand_config.get_value(variable_name).presence
      return handle_urls(explicit_value, config, css_urls) if explicit_value
      default = config['default']
      if default && default.starts_with?('$')
        if css_urls
          return "var(--#{default[1..-1]})"
        else
          return brand_variable_value(default[1..-1], active_brand_config, config_map, css_urls)
        end
      end

      # while in our sass, we want `url(/images/foo.png)`,
      # the Rails Asset Helpers expect us to not have the '/images/', eg: <%= image_tag('foo.png') %>
      default = default.sub(/^\/images\//, '') if config['type'] == 'image'
      handle_urls(default, config, css_urls)
    end

    def computed_variables(active_brand_config=nil)
      [
        ['ic-brand-primary', 'darken', 5],
        ['ic-brand-primary', 'darken', 10],
        ['ic-brand-primary', 'darken', 15],
        ['ic-brand-primary', 'lighten', 5],
        ['ic-brand-primary', 'lighten', 10],
        ['ic-brand-primary', 'lighten', 15],
        ['ic-brand-button--primary-bgd', 'darken', 5],
        ['ic-brand-button--primary-bgd', 'darken', 15],
        ['ic-brand-button--secondary-bgd', 'darken', 5],
        ['ic-brand-button--secondary-bgd', 'darken', 15],
        ['ic-brand-font-color-dark', 'lighten', 15],
        ['ic-brand-font-color-dark', 'lighten', 30],
        ['ic-link-color', 'darken', 10],
        ['ic-link-color', 'lighten', 10],
      ].each_with_object({}) do |(variable_name, darken_or_lighten, percent), memo|
        color = brand_variable_value(variable_name, active_brand_config, variables_map_with_image_urls)
        computed_color = CanvasColor::Color.new(color).send(darken_or_lighten, percent/100.0)
        memo["#{variable_name}-#{darken_or_lighten}ed-#{percent}"] = computed_color.to_s
      end
    end

    def all_brand_variable_values(active_brand_config=nil, css_urls=false)
      variables_map.each_with_object(computed_variables(active_brand_config)) do |(key, _), memo|
        memo[key] = brand_variable_value(key, active_brand_config, variables_map_with_image_urls, css_urls)
      end
    end

    def all_brand_variable_values_as_json(active_brand_config=nil)
      all_brand_variable_values(active_brand_config).to_json
    end

    def all_brand_variable_values_as_js(active_brand_config=nil)
      "CANVAS_ACTIVE_BRAND_VARIABLES = #{all_brand_variable_values_as_json(active_brand_config)};"
    end

    def all_brand_variable_values_as_css(active_brand_config=nil)
      ":root {
        #{all_brand_variable_values(active_brand_config, true).map{ |k, v| "--#{k}: #{v};"}.join("\n")}
      }"
    end

    def public_brandable_css_folder
      Pathname.new('public/dist/brandable_css')
    end

    def default_brand_folder
      public_brandable_css_folder.join('default')
    end

    def default_brand_file(type, high_contrast=false)
      default_brand_folder.join("variables#{high_contrast ? '-high_contrast' : ''}-#{default_variables_md5}.#{type}")
    end

    def high_contrast_overrides
      Class.new do
        def get_value(variable_name)
          {"ic-brand-primary" => "#0770A3", "ic-link-color" => "#0073A7"}[variable_name]
        end
      end.new
    end

    def default(type, high_contrast=false)
      bc = high_contrast ? high_contrast_overrides : nil
      send("all_brand_variable_values_as_#{type}", bc)
    end

    def save_default!(type, high_contrast=false)
      default_brand_folder.mkpath
      default_brand_file(type, high_contrast).write(default(type, high_contrast))
      move_default_to_s3_if_enabled!(type, high_contrast)
    end

    def save_default_files!
      [true, false].each do |high_contrast|
        ['js', 'css', 'json'].each { |type| save_default!(type, high_contrast) }
      end
    end

    def move_default_to_s3_if_enabled!(type, high_contrast=false)
      return unless defined?(Canvas) && Canvas::Cdn.enabled?
      s3_uploader.upload_file(public_default_path(type, high_contrast))
      begin
        File.delete(default_brand_file(type, high_contrast))
      rescue Errno::ENOENT # continue if something else deleted it in another process
      end
    end

    def s3_uploader
      @s3_uploaderer ||= Canvas::Cdn::S3Uploader.new
    end

    def public_default_path(type, high_contrast=false)
      "dist/brandable_css/default/variables#{high_contrast ? '-high_contrast' : ''}-#{default_variables_md5}.#{type}"
    end

    def variants
      @variants ||= CONFIG['variants'].keys.freeze
    end

    def brandable_variants
      @brandable_variants ||= CONFIG['variants'].select{|_, v| v['brandable']}.map{ |k,_| k }.freeze
    end

    def combined_checksums
      if defined?(ActionController) && ActionController::Base.perform_caching && defined?(@combined_checksums)
        return @combined_checksums
      end
      file = APP_ROOT.join(CONFIG['paths']['bundles_with_deps'] + SASS_STYLE)
      if file.exist?
        @combined_checksums = JSON.parse(file.read).each_with_object({}) do |(k, v), memo|
          memo[k] = v.symbolize_keys.slice(:combinedChecksum, :includesNoVariables)
        end.freeze
      elsif defined?(Rails) && Rails.env.production?
        raise "#{file.expand_path} does not exist. You need to run brandable_css before you can serve css."
      else
        # for dev/test there might be cases where you don't want it to raise an exception
        # if you haven't ran `brandable_css` and the manifest file doesn't exist yet.
        # eg: you want to test a controller action and you don't care that it links
        # to a css file that hasn't been created yet.
        default_value = {:combinedChecksum => "Error: unknown css checksum. you need to run brandable_css"}.freeze
        @combined_checksums = Hash.new(default_value).freeze
      end
    end

    # bundle path should be something like "bundles/speedgrader" or "plugins/analytics/something"
    def cache_for(bundle_path, variant)
      key = ["#{bundle_path}.scss", variant].join(CONFIG['manifest_key_seperator'])
      fingerprint = combined_checksums[key]
      raise "Fingerprint not found. #{bundle_path} #{variant}" unless fingerprint
      fingerprint
    end

    def all_fingerprints_for(bundle_path)
      variants.each_with_object({}) do |variant, object|
        object[variant] = cache_for(bundle_path, variant)
      end
    end
  end

  class BrandConfigWithOutCompileAssets < RuntimeError
    def initialize
      super <<-END

It looks like you are running a migration before running `rake canvas:compile_assets`
compile_assets needs to complete before running db:migrate if brand_configs have not run

run `rake canvas:compile_assets` and then try migrations again.

      END
    end
  end

  class DefaultMD5NotUpToDateError < RuntimeError
    def initialize
      super <<-END

Something has changed about the default variables or images used in the Theme Editor.
If you are seeing this and _you_ did not make changes to either app/stylesheets/brandable_variables.json
or one of the images it references, it probably meeans your local setup is out of date.

First, make sure you run `rake db:migrate`
and then run `./script/nuke_node.sh`

If that does not resolve the issue, it probably means you _did_ update one of those json variables
in app/stylesheets/brandable_variables.json or one of the images it references so you need to rename
the db migrations that makes sure when this change is deployed or checked out by anyone else
makes a new .css file for the css variables for each brand based on these new defaults.
To do that, run this command and then restart your rails process. (for local dev, if you want the
changes to show up in the ui, make sure you also run `rake db:migrate` afterwards).

ONLY DO THIS IF YOU REALLY DID MEAN TO MAKE A CHANGE TO THE DEFAULT BRANDING STUFF:

mv db/migrate/*_#{MIGRATION_NAME.underscore}_predeploy.rb \\
   db/migrate/#{BrandableCSS.migration_version}_#{MIGRATION_NAME.underscore}_predeploy.rb \\
&& \\
mv db/migrate/*_#{MIGRATION_NAME.underscore}_postdeploy.rb \\
   db/migrate/#{BrandableCSS.migration_version + 1}_#{MIGRATION_NAME.underscore}_postdeploy.rb

FYI, current variables are: #{BrandableCSS.things_that_go_into_defaults_md5}
END
    end
  end
end
