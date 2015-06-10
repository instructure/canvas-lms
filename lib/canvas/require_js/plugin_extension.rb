module Canvas
  module RequireJs
    module PluginExtension
      class << self
        # magical plugin js extension stuff
        #
        # given app/coffeescripts/foo.coffee in canvas-lms, if you want to
        # monkey patch it from your plugin, create
        # app/coffeescripts/extensions/foo.coffee (in your plugin) like so:
        #
        # define ->
        #   (Foo) ->
        #     Foo::zomg = -> "i added this method"
        #     Foo
        #
        # and that's it, no changes required in canvas-lms, no plugin
        # bundles, etc.
        #
        # note that Foo is not an explicit dependency, it magically figures
        # it out. also note that your module should return a function that
        # accepts and returns Foo. this function will magically wrap around
        # Foo so you can do stuff to it anytime somebody requires "foo" as
        # per usual.

        GLOB = "{gems,vendor}/plugins/*/app/coffeescripts/extensions"
        REGEXP = %r{(?:gems|vendor)/plugins/([^/]*)/app/coffeescripts/extensions}

        # added to require config paths so that when you require an
        # extended module, you instead get the glue module which gives you
        # the original plus the extensions
        def paths
          map.keys.inject({}) { |hash, file|
            hash["compiled/#{file}_without_extensions"] = "compiled/#{file}"
            hash["compiled/#{file}"] = "compiled/#{file}_with_extensions"
            hash
          }
        end

        def map
          @map ||= Dir["#{GLOB}/**/*.coffee"].inject({}) { |hash, ext|
            _, plugin, file = ext.match(%r{#{REGEXP}/(.*)\.coffee}).to_a
            hash[file] ||= []
            hash[file] << plugin
            hash
          }
        end

        # given a file, which plugins extend it?
        def infer_extension_plugins(file)
          Dir[GLOB].map { |match|
            match.sub(REGEXP, '\1')
          }
        end

        # create the glue module that requires the original and its
        # extensions. when your bundle (or whatever) requires the original
        # path, you'll get this module instead
        def generate(file, plugins = infer_extension_plugins(file))
          plugin_paths = plugins.map { |p| "#{p}/compiled/extensions/#{file}" }
          plugin_paths.unshift "compiled/#{file}_without_extensions"
          plugin_args = plugins.each_index.map { |i| "p#{i}" }
          plugin_calls = plugin_args.reverse.inject("orig"){ |s, a| "#{a}(#{s})" }
          FileUtils.mkdir_p(File.dirname("public/javascripts/compiled/#{file}"))
          File.open("public/javascripts/compiled/#{file}_with_extensions.js", "w") { |f|
            f.write <<-JS.gsub(/^              /, '')
              define(#{plugin_paths.inspect}, function(orig, #{plugin_args.join(', ')}) {
                return #{plugin_calls};
              });
            JS
          }
        end

        def generate_all
          map.each { |file, plugin| generate file, plugin }
        end
      end
    end
  end
end
