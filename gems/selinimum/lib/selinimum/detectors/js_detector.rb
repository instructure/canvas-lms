require_relative "generic_detector"
require_relative "../errors"

module Selinimum
  module Detectors
    class JSDetector < GenericDetector
      def can_process?(file, _)
        file =~ %r{\Apublic/javascripts/.*\.js\z}
      end

      def dependents_for(file)
        mod = module_from(file)
        bundles = find_js_bundles(mod)
        raise UnknownDependentsError, file if bundles.empty?
        raise TooManyDependentsError, file if bundles.include?("js:common") || bundles.include?("js:compiled/tinymce")
        bundles
      end

      def module_from(file)
        file.sub(%r{\Apublic/javascripts/(.*?)\.js}, "\\1")
      end

      def find_js_bundles(mod)
        (graph[mod + ".js"] || []).map do |bundle|
          bundle.sub(%r{\A(compiled/bundles/)?(.*)\.js\z}, "js:\\2")
        end
      end

      def graph
        @graph ||= begin
          graph = {}
          manifest = "public/optimized/build.txt"

          File.read(manifest).strip.split(/\n\n/).each do |data|
            bundle, files = data.split(/\n----------------\n/)
            files.split.each do |file|
              graph[file] ||= []
              graph[file] << bundle
            end
          end
          graph
        end
      end
    end
  end
end
