class WebConferenceSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :web_conferences, :settings, :text
  end

  def self.down
    remove_column :web_conferences, :settings
  end
end
