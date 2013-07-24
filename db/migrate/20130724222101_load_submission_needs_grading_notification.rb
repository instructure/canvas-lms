class LoadSubmissionNeedsGradingNotification < ActiveRecord::Migration

  tag :postdeploy

  def self.up
    Canvas::MessageHelper.create_notification({
      name: 'Submission Needs Grading',
      delay_for: 0,
      category: 'Grading'
    })
  end

  def self.down
    Notification.find_by_name('Submission Needs Grading').destroy
  end
end
