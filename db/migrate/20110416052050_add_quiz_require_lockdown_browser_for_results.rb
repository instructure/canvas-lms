class AddQuizRequireLockdownBrowserForResults < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quizzes, :require_lockdown_browser_for_results, :boolean
  end

  def self.down
    remove_column :quizzes, :require_lockdown_browser_for_results
  end
end
