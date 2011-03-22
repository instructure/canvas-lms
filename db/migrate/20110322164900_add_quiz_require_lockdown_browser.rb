class AddQuizRequireLockdownBrowser < ActiveRecord::Migration
  def self.up
    add_column :quizzes, :require_lockdown_browser, :boolean
  end

  def self.down
    remove_column :quizzes, :require_lockdown_browser
  end
end
