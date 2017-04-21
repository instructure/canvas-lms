class ChangeOriginalityReportScoreNull < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    change_column_null :originality_reports, :originality_score, true
  end
end
