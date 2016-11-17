class AddGradingPeriodGroupIdToGradingPeriods < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :grading_periods, :grading_period_group_id, :integer, :limit => 8
    add_index :grading_periods, :grading_period_group_id
    add_foreign_key :grading_periods, :grading_period_groups
  end

  def down
    remove_column :grading_periods, :grading_period_group_id
  end
end
