class ClearAnyMultipleGradingPeriodsFeatureFlags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::ClearAnyMultipleGradingPeriodsFeatureFlags.send_later_if_production_enqueue_args(
      :run,
      priority: Delayed::LOWER_PRIORITY,
      max_attempts: 1,
      n_strand: "DataFixup::ClearAnyMultipleGradingPeriodsFeatureFlags:#{Shard.current.database_server.id}"
    )
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
