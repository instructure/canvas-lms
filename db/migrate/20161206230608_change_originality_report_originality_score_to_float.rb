class ChangeOriginalityReportOriginalityScoreToFloat < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    change_column :originality_reports, :originality_score, :float, null: false
  end
end
