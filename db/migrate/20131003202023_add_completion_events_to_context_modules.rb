class AddCompletionEventsToContextModules < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_modules, :completion_events, :text
  end

  def self.down
    add_column :context_modules, :completion_events
  end
end
