require 'lib/canvas/require_js/plugin_extension'
require 'lib/canvas/require_js/client_app_extension'
module Canvas
  module RequireJs
    class << self
      def get_binding
        binding
      end

      PATH_REGEX = %r{.*?/javascripts/(plugins/)?(.*)\.js\z}
      JS_ROOT = "#{Rails.root}/public/javascripts"

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
          ember: 'bower/ember/ember',
          :common => 'compiled/bundles/common',
          :jqueryui => 'vendor/jqueryui',
          handlebars: 'symlink_to_node_modules/handlebars/dist/handlebars.runtime',
          '../../node_modules/axios' => 'symlink_to_node_modules/axios/dist/axios',
          'node_modules-version-of-backbone' => 'symlink_to_node_modules/backbone/backbone',
          'node_modules-version-of-moment' => 'symlink_to_node_modules/moment/min/moment-with-locales',
          'node_modules-version-of-react-modal' => 'symlink_to_node_modules/react-modal/dist/react-modal',
          moment: 'custom_moment_locales/mi_nz',
          'react-addons-css-transition-group' => 'react-addons-css-transition-group_requireJS',
          'react-addons-pure-render-mixin' => 'react-addons-pure-render-mixin_requireJS',
          'react-addons-test-utils' => 'react-addons-test-utils_requireJS',
          'react-addons-update' => 'react-addons-update_requireJS',
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
            'spin' => 'spin.js/spin' # because spin.js/jquery.spin.js does: "define(['spin'], ...)" instead of "define(['spin.js'], ...)"
          }
        }).to_json
      end

      def bundles
        @bundles ||= Canvas::RequireJs::ClientAppExtension.bundles.to_json
      end

      def packages
        @packages ||= [
          {name: 'ember-qunit', location: 'bower/ember-qunit/dist/amd'},
          {name: 'classnames',         location: 'symlink_to_node_modules/classnames', main: 'index'},
          {name: 'color-slicer',       location: 'symlink_to_node_modules/color-slicer', main: 'dist/color-slicer'},
          {name: 'd3',                 location: 'symlink_to_node_modules/d3', main: 'd3'},
          {name: 'fullcalendar',       location: 'symlink_to_node_modules/fullcalendar', main: 'dist/fullcalendar'},
          {name: 'ic-ajax',            location: 'symlink_to_node_modules/ic-ajax/dist/amd'},
          {name: 'ic-tabs',            location: 'symlink_to_node_modules/ic-tabs'},
          {name: 'instructure-ui',     location: 'symlink_to_node_modules/instructure-ui/dist', main: 'instructure-ui'},
          {name: 'instructure-icons',  location: 'symlink_to_node_modules/instructure-icons', main: 'react/index'},
          {name: 'lodash',             location: 'symlink_to_node_modules/lodash', main: 'lodash'},
          {name: 'page',               location: 'symlink_to_node_modules/page', main: 'page'},
          {name: 'qs',                 location: 'symlink_to_node_modules/qs', main: 'dist/qs'},
          {name: 'react',              location: 'symlink_to_node_modules/react', main: 'dist/react-with-addons'},
          {name: 'react-dom',          location: 'symlink_to_node_modules/react-dom', main: 'dist/react-dom'},
          {name: 'react-dnd',          location: 'symlink_to_node_modules/react-dnd', main: 'dist/ReactDnD.min'},
          {name: 'react-dnd-html5-backend', location: 'symlink_to_node_modules/react-dnd-html5-backend', main: 'dist/ReactDnDHTML5Backend.min'},
          {name: 'react-redux',        location: 'symlink_to_node_modules/react-redux', main: 'dist/react-redux.min'},
          {name: 'react-select-box',   location: 'symlink_to_node_modules/react-select-box', main: 'dist/react-select-box'},
          {name: 'react-tokeninput',   location: 'symlink_to_node_modules/react-tokeninput', main: 'dist/react-tokeninput'},
          {name: 'react-tabs',         location: 'symlink_to_node_modules/react-tabs', main: 'dist/react-tabs'},
          {name: 'react-tray',         location: 'symlink_to_node_modules/react-tray', main: 'dist/react-tray'},
          {name: 'redux',              location: 'symlink_to_node_modules/redux', main: 'dist/redux'},
          {name: 'redux-actions',      location: 'symlink_to_node_modules/redux-actions', main: 'dist/redux-actions.min'},
          {name: 'redux-logger',       location: 'symlink_to_node_modules/redux-logger', main: 'dist/index'},
          {name: 'redux-thunk',        location: 'symlink_to_node_modules/redux-thunk', main: 'dist/redux-thunk'},
          {name: 'tinymce',            location: 'symlink_to_node_modules/tinymce', main: 'tinymce'},
          {name: 'spin.js',            location: 'symlink_to_node_modules/spin.js', main: 'spin' },
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
            'ember': {
              deps: ['jquery', 'handlebars'],
              exports: 'Ember'
            },
            'vendor/FileAPI/FileAPI.min': {
              deps: ['jquery', 'vendor/FileAPI/config'],
              exports: 'FileAPI'
            },
            'fullcalendar/dist/lang-all': {
              deps: ['fullcalendar']
            },
            'vendor/bootstrap-select/bootstrap-select' : { deps: ['jquery'] },
            'vendor/jquery.jcrop': { deps: ['jquery'] },
            'vendor/md5': {
              exports: 'CryptoJS'
            },
            'vendor/i18n': {
              exports: 'I18n'
            },

            'handlebars': {
              exports: 'Handlebars'
            },

            'tinymce/tinymce' : { exports: 'tinymce'},
            'tinymce/plugins/autolink/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/media/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/paste/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/table/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/textcolor/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/link/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/directionality/plugin' : { deps: ['tinymce'] },
            'tinymce/plugins/lists/plugin' : { deps: ['tinymce'] },
            'tinymce/themes/modern/theme' : { deps: ['tinymce'] },
          }
        JS
      end
    end
  end
end
