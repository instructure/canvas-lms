class AddTitleToGradingPeriodGroups < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :grading_period_groups, :title, :string
  end

  def self.down
    remove_column :grading_period_groups, :title
  end
end
