class AddWeightedToGradingPeriodGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :grading_period_groups, :weighted, :boolean
  end

  def self.down
    remove_column :grading_period_groups, :weighted
  end
end
