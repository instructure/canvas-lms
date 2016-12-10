class AddCurrentToContextModuleProgressions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_module_progressions, :current, :boolean
  end

  def self.down
    remove_column :context_module_progressions, :current
  end
end
