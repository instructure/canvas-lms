class DropGradingPeriodGradesTable < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :grading_period_grades
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
