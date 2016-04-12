require_relative "js_detector"

module Selinimum
  module Detectors
    class CoffeeDetector < JSDetector
      def can_process?(file, _)
        file =~ %r{\Aapp/coffeescripts/.*\.coffee\z}
      end

      def module_from(file)
        "compiled/" + file.sub(%r{\Aapp/coffeescripts/(.*?)\.coffee}, "\\1")
      end
    end
  end
end
