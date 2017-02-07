module AcademicBenchmarks
  module Standards
    module Common
      def course_cache
        @course_cache ||= {}
      end

      def subject_cache
        @subject_cache ||= {}
      end

      def build_common_outcomes(ratings)
        course_cache.clear
        subject_cache.clear
        {
          migration_id: guid,
          vendor_guid: guid,
          is_global_standard: true,
          type: 'learning_outcome_group',
          outcomes: children.map {|c| c.build_outcomes(ratings, self)}.compact
        }
      end
    end
  end
end