require 'lib/canvas/require_js/plugin_extension'
require 'lib/canvas/require_js/client_app_extension'
module Canvas
  module RequireJs
    class << self
      @@matcher = nil
      def get_binding
        binding
      end

      PATH_REGEX = %r{.*?/javascripts/(plugins/)?(.*)\.js\z}
      JS_ROOT = "#{Rails.root}/public/javascripts"

      def matcher=(value)
        @@matcher = value
      end

      def matcher
        @@matcher || ENV['JS_SPEC_MATCHER'] || '**/*Spec.js'
      end

      # get all regular canvas (and plugin) bundles
      def app_bundles
        app_bundles = (
          Dir["#{JS_ROOT}/compiled/bundles/**/*.js"] +
          Dir["#{JS_ROOT}/plugins/*/compiled/bundles/**/*.js"]
        ).reject { |file| file =~ %r{/bundles/modules/} }
        .inject({}) { |hash, file|
            # plugins have their name prepended, since that's how we do the paths
            name = file.sub(PATH_REGEX, '\2')
            unless name == 'compiled/bundles/common'
              hash[name] = { :name => name, :exclude => ['common', 'compiled/tinymce'] }
            end
            hash
          }

        app_bundles.values.sort_by{ |b| b[:name] }.to_json[1...-1].gsub(/,\{/, ",\n    {")
      end

      def paths(cache_busting = false)
        @paths ||= {
          :common => 'compiled/bundles/common',
          :jqueryui => 'vendor/jqueryui',
          :instructureui => 'instructure-ui/'
        }.update(cache_busting ? cache_busting_paths : {}).
          update(plugin_paths).
          update(Canvas::RequireJs::PluginExtension.paths).
          update(Canvas::RequireJs::ClientAppExtension.paths).
          to_json.
          gsub(/([,{])/, "\\1\n    ")
      end

      def map
        @map ||= Canvas::RequireJs::ClientAppExtension.map.merge({
          '*' => {
            React: "react" # for misbehaving UMD like react-tabs
          }
        }).to_json
      end

      def bundles
        @bundles ||= Canvas::RequireJs::ClientAppExtension.bundles.to_json
      end

      def packages
        @packages ||= [
          {'name' => 'ic-ajax', 'location' => 'bower/ic-ajax/dist/amd'},
          {'name' => 'ic-styled', 'location' => 'bower/ic-styled'},
          {'name' => 'ic-menu', 'location' => 'bower/ic-menu'},
          {'name' => 'ic-tabs', 'location' => 'bower/ic-tabs/dist/amd'},
          {'name' => 'ic-droppable', 'location' => 'bower/ic-droppable/dist/amd'},
          {'name' => 'ic-sortable', 'location' => 'bower/ic-sortable/dist/amd'},
          {'name' => 'ic-modal', 'location' => 'bower/ic-modal/dist/amd'},
          {'name' => 'ic-lazy-list', 'location' => 'bower/ic-lazy-list'},
          {'name' => 'ember-qunit', 'location' => 'bower/ember-qunit/dist/amd'},
        ].to_json
      end

      def plugin_paths
        @plugin_paths ||= begin
          Dir['public/javascripts/plugins/*'].inject({}) { |hash, plugin|
            plugin = plugin.sub(%r{public/javascripts/plugins/}, '')
            hash[plugin] = "plugins/#{plugin}"
            hash
          }
        end
      end

      def cache_busting_paths
        { 'compiled/tinymce' => 'compiled/tinymce.js?v2' } # hack: increment to purge browser cached bundles after tiny change
      end

      def shims
        <<-JS.gsub(%r{\A +|^ {8}}, '')
          {
            'bower/react/react-dom': {
              exports: 'ReactDOM'
            },
            'bower/react-router/build/umd/ReactRouter': {
              deps: ['react'],
              exports: 'ReactRouter'
            },
            'bower/react-tray/dist/react-tray': {
              deps: ['react']
            },
            'bower/react-modal/dist/react-modal': {
              deps: ['react']
            },
            'bower/react-tokeninput/dist/react-tokeninput': {
              deps: ['react'],
            },
            'bower/react-select-box/dist/react-select-box': {
              deps: ['react'],
            },
            'bower/ember/ember': {
              deps: ['jquery', 'handlebars'],
              exports: 'Ember'
            },
            'bower/ember-data/ember-data': {
              deps: ['ember'],
              exports: 'DS'
            },
            'bower/handlebars/handlebars.runtime': {
              exports: 'Handlebars'
            },
            'bower/reflux/dist/reflux.js': {
              deps: ['react'],
              exports: 'Reflux'
            },
            'vendor/FileAPI/FileAPI.min': {
              deps: ['jquery', 'vendor/FileAPI/config'],
              exports: 'FileAPI'
            },
            'fixed-data-table': {
              deps: ['object_assign', 'react'],
              exports: 'fixed-data-table'
            },
            'vendor/bootstrap-select/bootstrap-select' : {
              deps: ['jquery'],
              exports: '$'
            },
            'vendor/jquery.jcrop': {
              deps: ['jquery'],
              exports: '$'
            },
            'vendor/jquery.smartbanner': {
              deps: ['jquery'],
              exports: '$'
            },
            'vendor/md5': {
              exports: 'CryptoJS'
            },
            'handlebars': {
              deps: ['bower/handlebars/handlebars.runtime.amd'],
              exports: 'Handlebars'
            },
            'vendor/i18n': {
              exports: 'I18n'
            },
            'vendor/react-infinite-scroll.min' : {
              deps: ['react'],
              exports: 'InfiniteScroll'
            },
            'bower/tinymce/tinymce' : {
              exports: 'tinymce'
            },
            'bower/axios/dist/axios' : {
              exports: 'axios'
            },
            'bower/tinymce/themes/modern/theme' : {
              deps: ['bower/tinymce/tinymce'],
              exports: 'tinymce'
            }
          }
        JS
      end
    end
  end
end
