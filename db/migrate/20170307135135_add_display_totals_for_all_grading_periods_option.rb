class AddDisplayTotalsForAllGradingPeriodsOption < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    add_column :grading_period_groups, :display_totals_for_all_grading_periods, :boolean
    change_column_default :grading_period_groups, :display_totals_for_all_grading_periods, false

    Account.where(id: GradingPeriodGroup.select(:account_id)).find_each do |account|
      DataFixup::BackfillNulls.run(
        GradingPeriodGroup.where(account_id: account.id),
        [:display_totals_for_all_grading_periods],
        default_value: account.feature_enabled?(:all_grading_periods_totals)
      )
    end
    Course.where(id: GradingPeriodGroup.select(:course_id)).find_each do |course|
      DataFixup::BackfillNulls.run(
        GradingPeriodGroup.where(course_id: course.id),
        [:display_totals_for_all_grading_periods],
        default_value: course.feature_enabled?(:all_grading_periods_totals)
      )
    end

    change_column_null_with_less_locking :grading_period_groups, :display_totals_for_all_grading_periods
  end

  def down
    remove_column :grading_period_groups, :display_totals_for_all_grading_periods
  end
end
