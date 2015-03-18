class AllowNullWeightOnGradingPeriods < ActiveRecord::Migration
  tag :predeploy

  def up
    change_column :grading_periods, :weight, :float, :null => true
  end

  def down
    change_column :grading_periods, :weight, :float, :null => false
  end
end
