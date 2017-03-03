module DataFixup
  module ClearAnyMultipleGradingPeriodsFeatureFlags
    def self.run
      FeatureFlag.where(feature: 'multiple_grading_periods').destroy_all
    end
  end
end
