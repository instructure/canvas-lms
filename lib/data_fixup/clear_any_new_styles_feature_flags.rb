module DataFixup
  module ClearAnyNewStylesFeatureFlags
    def self.run
      FeatureFlag.where(feature: 'new_styles').destroy_all
    end
  end
end
