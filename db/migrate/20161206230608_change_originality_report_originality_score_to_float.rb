class ChangeOriginalityReportOriginalityScoreToFloat < ActiveRecord::Migration
  tag :predeploy
  def change
    change_column :originality_reports, :originality_score, :float, null: false
  end
end
