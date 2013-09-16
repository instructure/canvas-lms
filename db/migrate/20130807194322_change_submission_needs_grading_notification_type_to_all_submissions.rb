class ChangeSubmissionNeedsGradingNotificationTypeToAllSubmissions < ActiveRecord::Migration
  tag :predeploy
  def self.up
    return unless Shard.current == Shard.default
    Notification.update_all({category: 'All Submissions'}, name: 'Submission Needs Grading')
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.update_all({category: 'Grading'}, name: 'Submission Needs Grading')
  end
end
