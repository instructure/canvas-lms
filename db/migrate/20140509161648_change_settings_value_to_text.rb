class ChangeSettingsValueToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :settings, :value, :text
  end

  def self.down
    change_column :settings, :value, :string
  end
end
