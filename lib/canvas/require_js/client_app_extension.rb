module Canvas
  module RequireJs
    module ClientAppExtension
      class << self
        SRC_DIR = 'client_apps' # relative to Rails.root
        JS_DIR = 'client_apps' # relative to /public/javascripts

        def paths
          app_names.reduce({}) do |paths, app_name|
            paths[app_name] = "client_apps/#{app_name}"
            paths
          end
        end

        def map
          app_names.reduce({}) do |map, app_name|
            mapfile = base_path(app_name, 'dist', "#{app_name}.map.json")

            if File.exists?(mapfile)
              map[app_name] = JSON.parse(File.read(mapfile))
            end

            map
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
      end
    end
  end
end