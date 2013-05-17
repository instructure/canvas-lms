class AddHomeworkSubmissionForExternalTools < ActiveRecord::Migration
  tag :predeploy
  def self.up
    add_column :context_external_tools, :has_homework_submission, :boolean
  end

  def self.down
    remove_column :context_external_tools, :has_homework_submission
  end
end
