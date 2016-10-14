class FixRidiculousWebConferenceDurations < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    WebConference.where('duration>?', WebConference::MAX_DURATION).find_ids_in_ranges do |min, max|
      WebConference.where('duration>?', WebConference::MAX_DURATION)
        .where(:id => min..max)
        .update_all(duration: nil)
    end
  end
end
