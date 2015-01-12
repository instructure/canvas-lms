class CreateGradingPeriodGradesJoinTable < ActiveRecord::Migration
  tag :predeploy

  def change
    create_table :grading_period_grades do |t|
      t.integer :enrollment_id, :limit => 8
      t.integer :grading_period_id, :limit => 8
      t.float :current_grade
      t.float :final_grade
      t.timestamps
    end

    add_foreign_key :grading_period_grades, :enrollments
    add_foreign_key :grading_period_grades, :grading_periods
    add_index :grading_period_grades, :enrollment_id
    add_index :grading_period_grades, :grading_period_id
  end
end
