require_relative "js_detector"

module Selinimum
  module Detectors
    class CoffeeDetector < JSDetector
      def can_process?(file, _)
        file =~ %r{\Aapp/coffeescripts/.*\.coffee\z}
      end
    end
  end
end
