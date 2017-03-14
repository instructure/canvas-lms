require_relative "generic_detector"
require_relative "../errors"

module Selinimum
  module Detectors
    class JSDetector < GenericDetector
      def can_process?(file, _)
        file =~ %r{\Apublic/javascripts/.*\.js\z}
      end

      # CommonsChunk entry point, plus the other two bundles on every page
      GLOBAL_BUNDLES = %w[
        js:vendor
        js:common
        js:appBootstrap
      ].freeze

      def dependents_for(file)
        bundles = find_js_bundles(file)
        raise UnknownDependentsError, file if bundles.empty?
        raise TooManyDependentsError, file if (GLOBAL_BUNDLES & bundles).any?
        bundles
      end

      def find_js_bundles(mod)
        (graph["./" + mod] || []).map { |bundle| "js:#{bundle}" }
      end

      def graph
        @graph ||= begin
          manifest = "public/dist/webpack-production/selinimum-manifest.json"
          if File.exist?(manifest)
            JSON.parse(File.read(manifest))
          else
            {}
          end
        end
      end
    end
  end
end
