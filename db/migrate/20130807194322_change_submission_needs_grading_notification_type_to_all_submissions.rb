class ChangeSubmissionNeedsGradingNotificationTypeToAllSubmissions < ActiveRecord::Migration
  tag :predeploy
  def self.up
    return unless Shard.current == Shard.default
    Notification.find_by_name('Submission Needs Grading').update_attributes(
      category: 'All Submissions'
    )
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.find_by_name('Submission Needs Grading').update_attributes(
      category: 'Grading'
    )
  end
end
