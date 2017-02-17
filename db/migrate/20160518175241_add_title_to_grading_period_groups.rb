class AddTitleToGradingPeriodGroups < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :grading_period_groups, :title, :string
  end

  def self.down
    remove_column :grading_period_groups, :title
  end
end
