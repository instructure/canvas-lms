require 'lib/canvas/require_js/plugin_extension'
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
          Dir["#{JS_ROOT}/compiled/bundles/*.js"] +
          Dir["#{JS_ROOT}/plugins/*/compiled/bundles/*.js"]
        ).inject({}) { |hash, file|
            # plugins have their name prepended, since that's we do the paths
            name = file.sub(PATH_REGEX, '\2')
            unless name == 'compiled/bundles/common'
              hash[name] = { :name => name, :exclude => ['common', 'compiled/tinymce'] }
            end
            hash
          }
    
        # inject any bundle extensions defined in plugins
        extensions_for("*").each do |bundle, extensions|
          if app_bundles["compiled/bundles/#{bundle}"]
            app_bundles["compiled/bundles/#{bundle}"][:include] = extensions
          else
            $stderr.puts "WARNING: can't extend #{bundle}, it doesn't exist"
          end
        end

        app_bundles.values.sort_by{ |b| b[:name] }.to_json[1...-1].gsub(/,\{/, ",\n    {")
      end

      # get extensions for a particular bundle (or all, if "*")
      def extensions_for(bundle, plugin_path = '')
        result = {}
        Dir["#{JS_ROOT}/plugins/*/compiled/bundles/extensions/#{bundle}.js"].each do |file|
          name = file.sub(PATH_REGEX, '\2')
          b = name.sub(%r{.*/}, '')
          result[b] ||= []
          result[b] << plugin_path + name
        end
        bundle == '*' ? result : (result[bundle.to_s] || [])
      end

      def paths(cache_busting = false)
        @paths ||= {
          :common => 'compiled/bundles/common',
          :jqueryui => 'vendor/jqueryui',
          :use => 'vendor/use',
          :uploadify => '../flash/uploadify/jquery.uploadify-3.1.min',
          'ic-dialog' => 'vendor/ic-dialog/dist/main.amd',
        }.update(cache_busting ? cache_busting_paths : {}).update(plugin_paths).update(Canvas::RequireJs::PluginExtension.paths).to_json.gsub(/([,{])/, "\\1\n    ")
      end

      def packages
        @packages ||= [
          {'name' => 'ic-ajax', 'location' => 'bower/ic-ajax'},
          {'name' => 'ic-styled', 'location' => 'bower/ic-styled'},
          {'name' => 'ic-menu', 'location' => 'bower/ic-menu'},
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
            'bower/ember/ember': {
              deps: ['jquery', 'handlebars'],
              attach: 'Ember'
            },
            'bower/ember-data/ember-data': {
              deps: ['ember'],
              attach: 'DS'
            },
            'bower/handlebars/handlebars.runtime': {
              attach: 'Handlebars'
            },
            'vendor/backbone': {
              deps: ['underscore', 'jquery'],
              attach: function(_, $){
                return Backbone;
              }
            },
            // slick grid shim
            'vendor/slickgrid/lib/jquery.event.drag-2.2': {
              deps: ['jquery'],
              attach: '$'
            },
            'vendor/slickgrid/slick.core': {
              deps: ['jquery', 'use!vendor/slickgrid/lib/jquery.event.drag-2.2'],
              attach: 'Slick'
            },
            'vendor/slickgrid/slick.grid': {
              deps: ['use!vendor/slickgrid/slick.core'],
              attach: 'Slick'
            },
            'vendor/slickgrid/slick.editors': {
              deps: ['use!vendor/slickgrid/slick.core'],
              attach: 'Slick'
            },
            'vendor/slickgrid/plugins/slick.rowselectionmodel': {
              deps: ['use!vendor/slickgrid/slick.core'],
              attach: 'Slick'
            },

            'uploadify' : {
              deps: ['jquery'],
              attach: '$'
            },

            'vendor/FileAPI/FileAPI.min': {
              deps: ['jquery', 'vendor/FileAPI/config'],
              attach: 'FileAPI'
            },

            'vendor/bootstrap/bootstrap-dropdown' : {
              deps: ['jquery'],
              attach: '$'
            },

            'vendor/bootstrap-select/bootstrap-select' : {
              deps: ['jquery'],
              attach: '$'
            },

            'vendor/jquery.jcrop': {
              deps: ['jquery'],
              attach: '$'
            }
          }
        JS
      end
    end
  end
end
