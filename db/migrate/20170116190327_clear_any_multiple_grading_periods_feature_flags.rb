class ClearAnyMultipleGradingPeriodsFeatureFlags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::ClearFeatureFlags.run_async('multiple_grading_periods')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
