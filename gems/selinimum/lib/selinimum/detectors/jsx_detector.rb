require_relative "js_detector"

module Selinimum
  module Detectors
    class JSXDetector < JSDetector
      def can_process?(file, _)
        file =~ %r{\Aapp/jsx/.*\.jsx\z}
      end

      def module_from(file)
        "jsx/" + file.sub(%r{\Aapp/jsx/(.*?)\.jsx}, "\\1")
      end
    end
  end
end

