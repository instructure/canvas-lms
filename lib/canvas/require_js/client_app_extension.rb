module Canvas
  module RequireJs
    module ClientAppExtension
      class << self
        SRC_DIR = 'client_apps' # relative to Rails.root
        JS_DIR = 'client_apps' # relative to /public/javascripts

        def paths
          app_names.reduce({}) do |paths, app_name|
            paths[app_name] = "#{JS_DIR}/#{app_name}"

            if extra_paths = load_config_file(app_name, 'paths.json')
              paths.merge!(extra_paths)
            end

            paths
          end
        end

        def map
          app_names.reduce({}) do |map, app_name|
            if custom_map = load_config_file(app_name, 'map.json')
              map[app_name] = custom_map
            end

            map
          end
        end

        def bundles
          app_names.reduce({}) do |bundles, app_name|
            if bundle_config = load_config_file(app_name, 'bundles.json')
              bundles.merge!(bundle_config)
            end

            bundles
          end
        end

        protected

        def base_path(*args)
          File.join(File.dirname(__FILE__), '..', '..', '..', SRC_DIR, *args)
        end

        def app_names
          client_apps = Dir.glob(base_path('*'))
            .select { |file| File.directory?(file) }
            .map { |file| File.basename(file) }
        end

        def load_config_file(app_name, file_name)
          config_file = base_path(app_name, 'dist', "#{app_name}.#{file_name}")

          if File.exist?(config_file)
            JSON.parse(File.read(config_file))
          end
        end
      end
    end
  end
end