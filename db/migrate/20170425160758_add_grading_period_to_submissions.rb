class AddGradingPeriodToSubmissions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :submissions, :grading_period_id, :integer, limit: 8
    add_foreign_key :submissions, :grading_periods
  end
end
