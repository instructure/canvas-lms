class ClearAllGradingPeriodsTotalsFeatureFlags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::ClearFeatureFlags.run_async('all_grading_periods_totals')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
