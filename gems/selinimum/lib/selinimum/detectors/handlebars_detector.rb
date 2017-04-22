require_relative "js_detector"

module Selinimum
  module Detectors
    class HandlebarsDetector < JSDetector
      def can_process?(file, _)
        file =~ %r{\Aapp/views/jst/.*\.handlebars\z}
      end
    end
  end
end
