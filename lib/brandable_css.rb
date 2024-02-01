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

module BrandableCSS
  APP_ROOT = (defined?(Rails) && Rails.root) || Pathname.pwd
  CONFIG = YAML.load_file(APP_ROOT.join("config/brandable_css.yml")).freeze
  BRANDABLE_VARIABLES = JSON.parse(File.read(APP_ROOT.join(CONFIG["paths"]["brandable_variables_json"]))).freeze
  MIGRATION_NAME = "RegenerateBrandFilesBasedOnNewDefaults"

  VARIABLE_HUMAN_NAMES = {
    "ic-brand-primary" => -> { I18n.t("Primary Brand Color") },
    "ic-brand-font-color-dark" => -> { I18n.t("Main Text Color") },
    "ic-link-color" => -> { I18n.t("Link Color") },
    "ic-brand-button--primary-bgd" => -> { I18n.t("Primary Button") },
    "ic-brand-button--primary-text" => -> { I18n.t("Primary Button Text") },
    "ic-brand-button--secondary-bgd" => -> { I18n.t("Secondary Button") },
    "ic-brand-button--secondary-text" => -> { I18n.t("Secondary Button Text") },
    "ic-brand-global-nav-bgd" => -> { I18n.t("Nav Background") },
    "ic-brand-global-nav-ic-icon-svg-fill" => -> { I18n.t("Nav Icon") },
    "ic-brand-global-nav-ic-icon-svg-fill--active" => -> { I18n.t("Nav Icon Active") },
    "ic-brand-global-nav-menu-item__text-color" => -> { I18n.t("Nav Text") },
    "ic-brand-global-nav-menu-item__text-color--active" => -> { I18n.t("Nav Text Active") },
    "ic-brand-global-nav-avatar-border" => -> { I18n.t("Nav Avatar Border") },
    "ic-brand-global-nav-menu-item__badge-bgd" => -> { I18n.t("Nav Badge") },
    "ic-brand-global-nav-menu-item__badge-bgd--active" => -> { I18n.t("Nav Badge Active") },
    "ic-brand-global-nav-menu-item__badge-text" => -> { I18n.t("Nav Badge Text") },
    "ic-brand-global-nav-menu-item__badge-text--active" => -> { I18n.t("Nav Badge Text Active") },
    "ic-brand-global-nav-logo-bgd" => -> { I18n.t("Nav Logo Background") },
    "ic-brand-header-image" => -> { I18n.t("Nav Logo") },
    "ic-brand-mobile-global-nav-logo" => -> { I18n.t("Responsive Global Nav Logo") },
    "ic-brand-watermark" => -> { I18n.t("Watermark") },
    "ic-brand-watermark-opacity" => -> { I18n.t("Watermark Opacity") },
    "ic-brand-favicon" => -> { I18n.t("Favicon") },
    "ic-brand-apple-touch-icon" => -> { I18n.t("Mobile Homescreen Icon") },
    "ic-brand-msapplication-tile-color" => -> { I18n.t("Windows Tile Color") },
    "ic-brand-msapplication-tile-square" => -> { I18n.t("Windows Tile: Square") },
    "ic-brand-msapplication-tile-wide" => -> { I18n.t("Windows Tile: Wide") },
    "ic-brand-right-sidebar-logo" => -> { I18n.t("Right Sidebar Logo") },
    "ic-brand-Login-body-bgd-color" => -> { I18n.t("Background Color") },
    "ic-brand-Login-body-bgd-image" => -> { I18n.t("Background Image") },
    "ic-brand-Login-body-bgd-shadow-color" => -> { I18n.t("Body Shadow") },
    "ic-brand-Login-logo" => -> { I18n.t("Login Logo") },
    "ic-brand-Login-Content-bgd-color" => -> { I18n.t("Top Box Background") },
    "ic-brand-Login-Content-border-color" => -> { I18n.t("Top Box Border") },
    "ic-brand-Login-Content-inner-bgd" => -> { I18n.t("Inner Box Background") },
    "ic-brand-Login-Content-inner-border" => -> { I18n.t("Inner Box Border") },
    "ic-brand-Login-Content-inner-body-bgd" => -> { I18n.t("Form Background") },
    "ic-brand-Login-Content-inner-body-border" => -> { I18n.t("Form Border") },
    "ic-brand-Login-Content-label-text-color" => -> { I18n.t("Login Label") },
    "ic-brand-Login-Content-password-text-color" => -> { I18n.t("Login Link Color") },
    "ic-brand-Login-footer-link-color" => -> { I18n.t("Login Footer Link") },
    "ic-brand-Login-footer-link-color-hover" => -> { I18n.t("Login Footer Link Hover") },
    "ic-brand-Login-instructure-logo" => -> { I18n.t("Login Instructure Logo") }
  }.freeze

  GROUP_NAMES = {
    "global_branding" => -> { I18n.t("Global Branding") },
    "global_navigation" => -> { I18n.t("Global Navigation") },
    "watermarks" => -> { I18n.t("Watermarks & Other Images") },
    "login" => -> { I18n.t("Login Screen") }
  }.freeze

  HELPER_TEXTS = {
    "ic-brand-header-image" => -> { I18n.t("Accepted formats: svg, png, jpg, gif") },
    "ic-brand-mobile-global-nav-logo" => -> { I18n.t("Appears at the top of the global navigation tray that opens on mobile sized screens. display height: 48px. Accepted formats: svg, png, jpg, gif") },
    "ic-brand-watermark" => -> { I18n.t("This image appears as a background watermark to your page. Accepted formats: png, svg, gif, jpeg") },
    "ic-brand-watermark-opacity" => -> { I18n.t("Specify the transparency of the watermark background image.") },
    "ic-brand-favicon" => -> { I18n.t("You can use a single 16x16, 32x32, 48x48 ico file.") },
    "ic-brand-apple-touch-icon" => -> { I18n.t("The shortcut icon for iOS/Android devices. 180x180 png") },
    "ic-brand-msapplication-tile-square" => -> { I18n.t("558x558 png, jpg, gif (1.8x the standard tile size, so it can be scaled up or down as needed)") },
    "ic-brand-msapplication-tile-wide" => -> { I18n.t("558x270 png, jpg, gif") },
    "ic-brand-right-sidebar-logo" => -> { I18n.t("A full-size logo that appears in the right sidebar on the Canvas dashboard. Ideal size is 360 x 140 pixels. Accepted formats: svg, png, jpeg, gif") },
    "ic-brand-Login-body-bgd-shadow-color" => -> { I18n.t("accepted formats: hex, rgba, rgb, hsl") }
  }.freeze

  class << self
    def variables_map
      @variables_map ||= BRANDABLE_VARIABLES.each_with_object({}) do |variable_group, memo|
        variable_group["variables"].each { |variable| memo[variable["variable_name"]] = variable }
      end.freeze
    end

    def variables_map_with_image_urls
      @variables_map_with_image_urls ||= variables_map.transform_values do |config|
        if config["type"] == "image"
          config.merge("default" => ActionController::Base.helpers.image_url(config["default"]))
        else
          config
        end
      end.freeze
    end

    def migration_version
      # ActiveRecord usually uses integer timestamps to generate migration versions but any integer
      # will work, so we just use the result of stripping out the alphabetic characters from the md5
      @migration_version ||= default_variables_md5.gsub(/[a-z]/, "").to_i
    end

    def default_variables_md5
      @default_variables_md5 ||= begin
        things_that_go_into_defaults_md5 = variables_map.transform_values do |value|
          case value["type"]
          when "image"
            # to make consistent md5s whether the cdn is enabled or not, don't include hostname in defaults
            ActionController::Base.helpers.image_path(value["default"], host: "")
          else
            value["default"]
          end
        end

        Digest::MD5.hexdigest(things_that_go_into_defaults_md5.to_json).freeze
      end
    end

    def handle_urls(value, config, css_urls)
      return value unless config["type"] == "image" && css_urls

      "url('#{value}')" if value.present?
    end

    # gets the *effective* value for a brandable variable
    def brand_variable_value(variable_name, active_brand_config = nil, config_map = variables_map, css_urls = false)
      config = config_map[variable_name]
      explicit_value = active_brand_config && active_brand_config.get_value(variable_name).presence
      return handle_urls(explicit_value, config, css_urls) if explicit_value

      default = config["default"]
      if default&.starts_with?("$")
        if css_urls
          return "var(--#{default[1..]})"
        else
          return brand_variable_value(default[1..], active_brand_config, config_map, css_urls)
        end
      end

      # while in our sass, we want `url(/images/foo.png)`,
      # the Rails Asset Helpers expect us to not have the '/images/', eg: <%= image_tag('foo.png') %>
      default = default.sub(%r{^/images/}, "") if config["type"] == "image"
      handle_urls(default, config, css_urls)
    end

    def computed_variables(active_brand_config = nil)
      [
        ["ic-brand-primary", "darken", 5],
        ["ic-brand-primary", "darken", 10],
        ["ic-brand-primary", "darken", 15],
        ["ic-brand-primary", "lighten", 5],
        ["ic-brand-primary", "lighten", 10],
        ["ic-brand-primary", "lighten", 15],
        ["ic-brand-button--primary-bgd", "darken", 5],
        ["ic-brand-button--primary-bgd", "darken", 15],
        ["ic-brand-button--secondary-bgd", "darken", 5],
        ["ic-brand-button--secondary-bgd", "darken", 15],
        ["ic-brand-font-color-dark", "lighten", 15],
        ["ic-brand-font-color-dark", "lighten", 28],
        ["ic-link-color", "darken", 10],
        ["ic-link-color", "lighten", 10],
      ].each_with_object({}) do |(variable_name, darken_or_lighten, percent), memo|
        color = brand_variable_value(variable_name, active_brand_config, variables_map_with_image_urls)
        computed_color = CanvasColor::Color.new(color).send(darken_or_lighten, percent / 100.0)
        memo["#{variable_name}-#{darken_or_lighten}ed-#{percent}"] = computed_color.to_s
      end
    end

    def all_brand_variable_values(active_brand_config = nil, css_urls = false)
      variables_map.each_with_object(computed_variables(active_brand_config)) do |(key, _), memo|
        memo[key] = brand_variable_value(key, active_brand_config, variables_map_with_image_urls, css_urls)
      end
    end

    def all_brand_variable_values_as_json(active_brand_config = nil)
      all_brand_variable_values(active_brand_config).to_json
    end

    def all_brand_variable_values_as_js(active_brand_config = nil)
      "CANVAS_ACTIVE_BRAND_VARIABLES = #{all_brand_variable_values_as_json(active_brand_config)};"
    end

    def all_brand_variable_values_as_css(active_brand_config = nil)
      ":root {
        #{all_brand_variable_values(active_brand_config, true).map { |k, v| "--#{k}: #{v};" }.join("\n")}
      }"
    end

    def public_brandable_css_folder
      Pathname.new("public/dist/brandable_css")
    end

    def default_brand_folder
      public_brandable_css_folder.join("default")
    end

    def default_brand_file(type, high_contrast = false)
      default_brand_folder.join("variables#{high_contrast ? "-high_contrast" : ""}-#{default_variables_md5}.#{type}")
    end

    def high_contrast_overrides
      Class.new do
        def get_value(variable_name)
          { "ic-brand-primary" => "#0770A3", "ic-link-color" => "#0073A7" }[variable_name]
        end
      end.new
    end

    def default(type, high_contrast = false)
      bc = high_contrast ? high_contrast_overrides : nil
      send(:"all_brand_variable_values_as_#{type}", bc)
    end

    def save_default!(type, high_contrast = false)
      default_brand_folder.mkpath
      default_brand_file(type, high_contrast).write(default(type, high_contrast))
      move_default_to_s3_if_enabled!(type, high_contrast)
    end

    def save_default_files!
      [true, false].each do |high_contrast|
        %w[js css json].each { |type| save_default!(type, high_contrast) }
      end
    end

    def move_default_to_s3_if_enabled!(type, high_contrast = false)
      return unless defined?(Canvas) && Canvas::Cdn.enabled?

      s3_uploader.upload_file(public_default_path(type, high_contrast))
      begin
        File.delete(default_brand_file(type, high_contrast))
      rescue Errno::ENOENT
        # continue if something else deleted it in another process
      end
    end

    def s3_uploader
      @s3_uploaderer ||= Canvas::Cdn::S3Uploader.new
    end

    def public_default_path(type, high_contrast = false)
      "dist/brandable_css/default/variables#{high_contrast ? "-high_contrast" : ""}-#{default_variables_md5}.#{type}"
    end

    def variants
      @variants ||= CONFIG["variants"].keys.freeze
    end

    def brandable_variants
      @brandable_variants ||= CONFIG["variants"].select { |_, v| v["brandable"] }.map { |k, _| k }.freeze
    end

    def combined_checksums
      if defined?(ActionController) && ActionController::Base.perform_caching && defined?(@combined_checksums)
        return @combined_checksums
      end

      file = APP_ROOT.join(CONFIG["paths"]["bundles_with_deps"])
      if file.exist?
        @combined_checksums = JSON.parse(file.read).transform_values do |v|
          v.symbolize_keys.slice(:combinedChecksum, :includesNoVariables)
        end.freeze
      elsif defined?(Rails) && Rails.env.production?
        raise "#{file.expand_path} does not exist. You need to run `yarn run build:css` before you can serve css."
      else
        # for dev/test there might be cases where you don't want it to raise an exception
        # if you haven't ran `brandable_css` and the manifest file doesn't exist yet.
        # eg: you want to test a controller action and you don't care that it links
        # to a css file that hasn't been created yet.
        default_value = { combinedChecksum: "Error: unknown css checksum. you need to run brandable_css" }.freeze
        @combined_checksums = Hash.new(default_value).freeze
      end
    end

    # javascript needs to know the checksums of the available variants for each
    # handlebars template so that it loads the corresponding stylesheet when the
    # template is rendered at runtime
    def handlebars_index_json
      if defined?(ActionController) && ActionController::Base.perform_caching && defined?(@handlebars_index_json)
        return @handlebars_index_json
      end

      file = APP_ROOT.join(CONFIG.dig("indices", "handlebars", "path"))
      unless file.exist?
        raise "#{file.expand_path} does not exist. You need to run `yarn run build:css` before you can serve css."
      end

      @handlebars_index_json = file.read.rstrip
    end

    # bundle path should be something like "bundles/speedgrader" or "plugins/analytics/something"
    def cache_for(bundle_path, variant)
      key = ["#{bundle_path}.scss", variant].join(CONFIG["manifest_key_seperator"])
      fingerprint = combined_checksums[key]
      raise "Fingerprint not found. #{bundle_path} #{variant}" unless fingerprint

      fingerprint
    end

    def all_fingerprints_for(bundle_path)
      variants.index_with do |variant|
        cache_for(bundle_path, variant)
      end
    end
  end
end
