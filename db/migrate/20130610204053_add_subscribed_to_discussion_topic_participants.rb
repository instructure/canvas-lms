class AddSubscribedToDiscussionTopicParticipants < ActiveRecord::Migration
  tag :predeploy
  
  def self.up
    add_column :discussion_topic_participants, :subscribed, :boolean
  end

  def self.down
    remove_column :discussion_topic_participants, :subscribed
  end
end
