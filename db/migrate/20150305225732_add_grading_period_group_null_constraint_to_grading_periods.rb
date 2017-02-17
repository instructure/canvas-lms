class AddGradingPeriodGroupNullConstraintToGradingPeriods < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    GradingPeriod.where(grading_period_group_id: nil).delete_all
    change_column :grading_periods, :grading_period_group_id, :integer, :null => false
  end

  def down
    change_column :grading_periods, :grading_period_group_id, :integer, :null => true
  end
end
