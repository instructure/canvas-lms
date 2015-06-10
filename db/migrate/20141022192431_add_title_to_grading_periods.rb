class AddTitleToGradingPeriods < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :grading_periods, :title, :string
  end

  def self.down
    remove_column :grading_periods, :title
  end
end
