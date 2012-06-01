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

      def paths
        @paths ||= {
          :common => 'compiled/bundles/common',
          :jqueryui => 'vendor/jqueryui',
          :uploadify => '../flash/uploadify/jquery.uploadify.v2.1.4',
          :use => 'vendor/use',
        }.update(plugin_paths).to_json.gsub(/([,{])/, "\\1\n    ")
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

      def shims
        <<-JS.gsub(%r{\A +|^ {8}}, '')
          {
            'vendor/backbone': {
              deps: ['underscore', 'jquery'],
              attach: function(_, $){
                return Backbone;
              }
            },
        
            // slick grid shim
            'vendor/slickgrid/lib/jquery.event.drag-2.0.min': {
              deps: ['jquery'],
              attach: '$'
            },
            'vendor/slickgrid/slick.core': {
              deps: ['jquery', 'use!vendor/slickgrid/lib/jquery.event.drag-2.0.min'],
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
            }
          }
        JS
      end
    end
  end
end