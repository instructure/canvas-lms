module DataFixup
  module ClearFeatureFlags
    def self.run_async(feature_flag)
      DataFixup::ClearFeatureFlags.send_later_if_production_enqueue_args(
        :run,
        {
          priority: Delayed::LOWER_PRIORITY,
          max_attempts: 1,
          n_strand: "DataFixup::ClearFeatureFlags:#{feature_flag}:#{Shard.current.database_server.id}"
        },
        feature_flag
      )
    end

    def self.run(feature_flag)
      FeatureFlag.where(feature: feature_flag).destroy_all
    end
  end
end
