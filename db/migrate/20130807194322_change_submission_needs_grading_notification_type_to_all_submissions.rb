class ChangeSubmissionNeedsGradingNotificationTypeToAllSubmissions < ActiveRecord::Migration
  tag :predeploy
  def self.up
    return unless Shard.current == Shard.default
    Notification.where(name: 'Submission Needs Grading').update_all(category: 'All Submissions')
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.where(name: 'Submission Needs Grading').update_all(category: 'Grading')
  end
end
