require_relative "js_detector"

module Selinimum
  module Detectors
    class JSXDetector < JSDetector
      def can_process?(file, _)
        file =~ %r{\Aapp/jsx/.*\.jsx\z}
      end
    end
  end
end

