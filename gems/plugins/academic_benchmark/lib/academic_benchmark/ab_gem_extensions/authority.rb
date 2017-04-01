require_relative 'common'

module AcademicBenchmarks
  module Standards
    class Authority
      include Common
      def document_cache
        @document_cache ||= {}
      end

      def build_outcomes(ratings={}, _parent=nil)
        document_cache.clear
        build_common_outcomes(ratings).merge!({
          title: description,
          description: "#{code} - #{description}",
        })
      end
    end
  end
end
