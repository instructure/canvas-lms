class AddMockInterviewScore < ActiveRecord::Migration
  tag :predeploy
  def change
  	add_column :course71_project_scores, :total_score____mock_interview__feedback_, :integer
  	add_column :course73_project_scores, :total_score____mock_interview__feedback_, :integer
  end
end
