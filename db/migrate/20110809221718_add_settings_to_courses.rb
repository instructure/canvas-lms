class AddSettingsToCourses < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :courses, :settings, :text
  end

  def self.down
    remove_column :courses, :settings
  end
end
