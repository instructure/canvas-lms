class WebConferenceSettings < ActiveRecord::Migration
  def self.up
    add_column :web_conferences, :settings, :text
  end

  def self.down
    remove_column :web_conferences, :settings
  end
end
