class AddSubmissionIdToOriginalityReports < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :originality_reports, :submission_id, :integer, limit: 8, null: false
    add_foreign_key :originality_reports, :submissions
    add_index :originality_reports, :submission_id
  end
end
