class LoadQuizRegradeFinishedNotification < ActiveRecord::Migration
  tag :predeploy
  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
      name: 'Quiz Regrade Finished',
      delay_for: 0,
      category: 'Grading'
    })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.find_by_name('Quiz Regrade Finished').destroy
  end
end
