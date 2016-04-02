require 'pathname'
require 'yaml'
require 'open3'

# Some of the functionality for fingerprint lookup here is mirrored in
# frontend_build/brandableCss.js, because shelling out to run this
# stuff take FOREVER in the webpack build.  That means for the time being,
# changes here if they happen may need to be mirrored in that file.

module BrandableCSS
  APP_ROOT = defined?(Rails) && Rails.root || Pathname.pwd
  CONFIG = YAML.load_file(APP_ROOT.join('config/brandable_css.yml')).freeze
  BRANDABLE_VARIABLES = JSON.parse(File.read(APP_ROOT.join(CONFIG['paths']['brandable_variables_json']))).freeze

  use_compressed = (defined?(Rails) && Rails.env.production?) || (ENV['RAILS_ENV'] == 'production')
  SASS_STYLE = ENV['SASS_STYLE'] || ((use_compressed ? 'compressed' : 'nested')).freeze

  VARIABLE_HUMAN_NAMES = {
    "ic-brand-primary" => lambda { I18n.t("Primary Color") },
    "ic-brand-button--primary-bgd" => lambda { I18n.t("Primary Button") },
    "ic-brand-button--primary-text" => lambda { I18n.t("Primary Button Text") },
    "ic-brand-button--secondary-bgd" => lambda { I18n.t("Secondary Button") },
    "ic-brand-button--secondary-text" => lambda { I18n.t("Secondary Button Text") },
    "ic-link-color" => lambda { I18n.t("Link") },
    "ic-brand-global-nav-bgd" => lambda { I18n.t("Nav Background") },
    "ic-brand-global-nav-ic-icon-svg-fill" => lambda { I18n.t("Nav Icon") },
    "ic-brand-global-nav-ic-icon-svg-fill--active" => lambda { I18n.t("Nav Icon Active") },
    "ic-brand-global-nav-menu-item__text-color" => lambda { I18n.t("Nav Text") },
    "ic-brand-global-nav-menu-item__text-color--active" => lambda { I18n.t("Nav Text Active") },
    "ic-brand-global-nav-avatar-border" => lambda { I18n.t("Nav Avatar Border") },
    "ic-brand-global-nav-menu-item__badge-bgd" => lambda { I18n.t("Nav Badge") },
    "ic-brand-global-nav-logo-bgd" => lambda { I18n.t("Nav Logo Background") },
    "ic-brand-header-image" => lambda { I18n.t("Nav Logo") },
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
    "ic-brand-Login-Content-button-bgd" => lambda { I18n.t("Login Button") },
    "ic-brand-Login-Content-button-text" => lambda { I18n.t("Login Button Text") },
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

    # gets the *effective* value for a brandable variable
    def brand_variable_value(variable_name, active_brand_config=nil)
      explicit_value = active_brand_config && active_brand_config.get_value(variable_name).presence
      return explicit_value if explicit_value
      config = variables_map[variable_name]
      default = config['default']
      return brand_variable_value(default[1..-1], active_brand_config) if default && default.starts_with?('$')

      # while in our sass, we want `url(/images/foo.png)`,
      # the Rails Asset Helpers expect us to not have the '/images/', eg: <%= image_tag('foo.png') %>
      default = default.sub(/^\/images\//, '') if config['type'] == 'image'
      default
    end

    def branded_scss_folder
      Pathname.new(CONFIG['paths']['branded_scss_folder'])
    end

    def variants
      @variants ||= CONFIG['variants'].map{|(k)| k }.freeze
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
        raise "#{file.expand_path} does not exist. You need to run #{cli} before you can serve css."
      else
        # for dev/test there might be cases where you don't want it to raise an exception
        # if you haven't ran `brandable_css` and the manifest file doesn't exist yet.
        # eg: you want to test a controller action and you don't care that it links
        # to a css file that hasn't been created yet.
        default_value = {combinedChecksum: "Error: unknown css checksum. you need to run #{cli}"}.freeze
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

    def cli
      './node_modules/.bin/brandable_css'
    end

    def compile_all!
      run_cli!
    end

    def compile_brand!(brand_id, opts=nil)
      run_cli!('--brand-id', brand_id, opts)
    end

    private

    def run_cli!(*args)
      opts = args.extract_options!
      # this makes sure the symlinks to app/stylesheets/plugins/analytics, etc exist
      # so their scss files can be picked up and compiled with everything else
      require 'config/initializers/plugin_symlinks'

      command = [cli].push(*args).shelljoin
      msg = "running BrandableCSS CLI: #{command}"
      Rails.logger.try(:debug, msg) if defined?(Rails)

      percent_complete = 0
      Open3.popen2e(command) do |_stdin, stdout_and_stderr, wait_thr|
        stdout_and_stderr.each do |line|
          puts line.chomp!

          # This is a good-enough-for-now approximation to show the progress
          # bar in the UI.  Since we don't know exactly how many files there are,
          # it will progress towards 100% but never quite hit it until it is complete.
          # Each tick it will cut 4% of the remaining percentage. Meaning it will look like
          # it goes fast at first but then slows down, but will always keep moving.
          if opts && opts[:on_progress] && line.starts_with?('compiled ')
            percent_complete += (100.0 - percent_complete) * 0.04
            opts[:on_progress].call(percent_complete)
          end
        end
        raise("Error #{msg}") unless wait_thr.value.success?
      end
    end
  end

end
