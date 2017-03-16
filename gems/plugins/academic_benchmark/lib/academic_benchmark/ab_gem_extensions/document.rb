require_relative 'common'

module AcademicBenchmarks
  module Standards
    class Document
      include Common
      def build_outcomes(ratings={}, _parent=nil)
        build_common_outcomes(ratings).merge!({
          title: title,
          description: title,
        })
      end
    end
  end
end
