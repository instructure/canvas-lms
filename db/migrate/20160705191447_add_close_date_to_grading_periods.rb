class AddCloseDateToGradingPeriods < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :grading_periods, :close_date, :datetime
  end

  def self.down
    remove_column :grading_periods, :close_date
  end
end
