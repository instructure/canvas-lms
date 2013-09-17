class LoadSubmissionNeedsGradingNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
      name: 'Submission Needs Grading',
      delay_for: 0,
      category: 'Grading'
    })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.find_by_name('Submission Needs Grading').destroy
  end
end
