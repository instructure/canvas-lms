class AddDisabledToPluginSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :plugin_settings, :disabled, :boolean
  end

  def self.down
    remove_column :plugin_settings, :disabled
  end
end
