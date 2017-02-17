class AddSettingsToCourses < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :courses, :settings, :text
  end

  def self.down
    remove_column :courses, :settings
  end
end
