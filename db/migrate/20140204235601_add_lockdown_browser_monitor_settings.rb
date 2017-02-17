class AddLockdownBrowserMonitorSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :quizzes, :require_lockdown_browser_monitor, :boolean
    add_column :quizzes, :lockdown_browser_monitor_data, :text
  end

  def self.down
    remove_column :quizzes, :require_lockdown_browser_monitor
    remove_column :quizzes, :lockdown_browser_monitor_data
  end
end
