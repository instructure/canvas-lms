class AddGradingPeriodsForeignKeys < ActiveRecord::Migration
  tag :predeploy

  def up
    add_foreign_key :grading_periods, :courses
    add_foreign_key :grading_periods, :accounts
  end

  def down
    remove_foreign_key :grading_periods, :courses
    remove_foreign_key :grading_periods, :accounts
  end
end