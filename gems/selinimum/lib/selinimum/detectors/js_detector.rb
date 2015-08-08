require_relative "generic_detector"

module Selinimum
  module Detectors
    class JsDetector < GenericDetector
      def can_process?(file)
        file =~ %r{\Apublic/javascripts/.*\.js\z}
      end

      def dependents_for(file, type = :js)
        bundles_for(file).map { |bundle| "#{type}:#{bundle}" }
      end

      def bundles_for(file)
        mod = module_from(file)
        bundles = find_js_bundles(mod)
        raise UnknownDependenciesError, file if bundles.empty?
        raise TooManyDependenciesError, file if bundles.include?("common")
        bundles
      end

      def module_from(file)
        file.sub(%r{\Apublic/javascripts/(.*?)\.js}, "\\1")
      end

      def find_js_bundles(mod)
        RequireJSLite.find_bundles_for(mod).map do |bundle|
          bundle.sub(%r{\Aapp/coffeescripts/bundles/(.*).coffee\z}, "\\1")
        end
      end

      def format_route_dependencies(routes)
        routes.map { |route| "route:#{route}" }
      end
    end

    class CSSDetector < JsDetector
      def can_process?(file)
        file =~ %r{\Aapp/stylesheets/.*css\z}
      end

      def dependents_for(file)
        super file, :css
      end

      def bundles_for(file)
        if file =~ %r{/jst/}
          file = file.sub("stylesheets", "views").sub(".scss", ".handlebars")
          return super file
        end

        bundles = find_css_bundles(file)
        raise TooManyDependenciesError, file if bundles.include?("common")
        bundles
      end

      def find_css_bundles(file)
        SASSLite.find_bundles_for(file).map do |bundle|
          bundle.sub(%r{\Aapp/coffeescripts/bundles/(.*).coffee\z}, "\\1")
        end
      end
    end

    class CoffeeDetector < JsDetector
      def can_process?(file)
        file =~ %r{\Aapp/coffeescripts/.*\.coffee\z}
      end

      def module_from(file)
        "compiled/" + file.sub(%r{\Aapp/coffeescripts/(.*?)\.coffee}, "\\1")
      end
    end

    class JsxDetector < JsDetector
      def can_process?(file)
        file =~ %r{/\Aapp/jsx/.*\.jsx\z}
      end

      def module_from(file)
        "jsx/" + file.sub(%r{\Aapp/jsx/(.*?)\.jsx}, "\\1")
      end
    end

    # TODO: partials
    class HandlebarsDetector < JsDetector
      def can_process?(file)
        file =~ %r{app/views/jst/.*\.handlebars\z}
      end

      def module_from(file)
        "jst/" + file.sub(%r{\Aapp/views/jst/(.*?)\.handlebars}, "\\1").sub(/(\A|\/)_/, "")
      end
    end
  end

  module SASSLite
    def self.find_bundles_for(*)
      # TODO: https://github.com/xzyfer/sass-graph
    end
  end

  module RequireJSLite
    def self.find_bundles_for(*)
      # TODO: https://www.npmjs.com/package/madge
    end
  end
end
