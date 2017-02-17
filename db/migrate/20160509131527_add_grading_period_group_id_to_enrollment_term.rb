class AddGradingPeriodGroupIdToEnrollmentTerm < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :enrollment_terms, :grading_period_group_id, :integer, :limit => 8
    add_index :enrollment_terms, :grading_period_group_id
    add_foreign_key :enrollment_terms, :grading_period_groups
  end

  def down
    remove_column :enrollment_terms, :grading_period_group_id
  end
end
