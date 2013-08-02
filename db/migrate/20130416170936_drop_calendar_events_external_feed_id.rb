class DropCalendarEventsExternalFeedId < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :calendar_events, :external_feed_id
  end

  def self.down
    add_column :calendar_events, :external_feed_id, :integer
  end
end
