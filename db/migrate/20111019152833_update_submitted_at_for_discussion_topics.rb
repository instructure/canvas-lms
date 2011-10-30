class UpdateSubmittedAtForDiscussionTopics < ActiveRecord::Migration
  def self.up
    Submission.update_all("submitted_at = created_at", ["submission_type = ?", "discussion_topic"])
  end

  def self.down
  end
end
