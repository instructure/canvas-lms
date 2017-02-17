class AllowNullWeightOnGradingPeriods < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :grading_periods, :weight, :float, :null => true
  end

  def down
    change_column :grading_periods, :weight, :float, :null => false
  end
end
