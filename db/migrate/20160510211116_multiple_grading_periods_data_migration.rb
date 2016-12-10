class MultipleGradingPeriodsDataMigration < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::MultipleGradingPeriodsDataMigration.send_later_if_production_enqueue_args(
      :run,
      priority: Delayed::LOW_PRIORITY,
      strand: "multiple_grading_periods_data_migration",
      max_attempts: 1
    )
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
