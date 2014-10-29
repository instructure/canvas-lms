class RemoveCourseIdAndAccountIdFromGradingPeriods < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :grading_periods, :course_id
    remove_column :grading_periods, :account_id
  end

  def down
    add_column :grading_periods, :course_id, :integer, :limit => 8
    add_column :grading_periods, :account_id, :integer, :limit => 8
    add_foreign_key :grading_periods, :courses
    add_foreign_key :grading_periods, :accounts
    add_index :grading_periods, :course_id
    add_index :grading_periods, :account_id
  end
end
