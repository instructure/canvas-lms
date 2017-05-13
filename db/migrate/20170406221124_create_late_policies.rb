class CreateLatePolicies < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :late_policies do |t|
      t.belongs_to :course, foreign_key: true, limit: 8, index: true, null: false

      t.boolean :missing_submission_deduction_enabled, null: false, default: false
      t.decimal :missing_submission_deduction, precision: 5, scale: 2, null: false, default: 0

      t.boolean :late_submission_deduction_enabled, null: false, default: false
      t.decimal :late_submission_deduction, precision: 5, scale: 2, null: false, default: 0
      t.string :late_submission_interval, limit: 16, null: false, default: 'day'

      t.boolean :late_submission_minimum_percent_enabled, null: false, default: false
      t.decimal :late_submission_minimum_percent, precision: 5, scale: 2, null: false, default: 0

      t.timestamps null: false
    end
  end
end
