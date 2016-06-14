require_relative "js_detector"

module Selinimum
  module Detectors
    class HandlebarsDetector < JSDetector
      def can_process?(file)
        file =~ %r{\Aapp/views/jst/.*\.handlebars\z}
      end

      # let the Embers die out, not worth the effort to selinimize :P
      def module_from(file)
        "jst/" + file.sub(%r{\Aapp/views/jst/(.*?)\.handlebars}, "\\1")
      end

      def dependents_for(file)
        dependent_modules_for(file).inject([]) do |result, f|
          result.concat super(f)
        end
      end

      def dependent_modules_for(file)
        # if not a partial, it's just a module like any other, so we're done
        return [file] if file !~ %r{/_}

        # trace partials back to template
        (template_graph[file] || []).inject([]) do |result, dependent|
          result.concat dependent_modules_for(dependent)
        end.uniq
      end

      def template_graph
        @template_graph ||= Dir["app/views/jst/**/*.handlebars"].each_with_object({}) do |file, graph|
          partials = File.read(file).scan(/\{\{>\s?\[?(.+?)\]?( .*?)?}}/).map { |m| m[0].strip }.uniq
          partials.each do |partial|
            partial.sub!(/\A(.*\/)(.*)/, "app/views/jst/\\1_\\2.handlebars")
            graph[partial] ||= []
            graph[partial] << file
          end
        end
      end
    end
  end
end
