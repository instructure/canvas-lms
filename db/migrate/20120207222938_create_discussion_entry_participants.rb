class CreateDiscussionEntryParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "discussion_entry_participants" do |t|
      t.integer "discussion_entry_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.string "workflow_state"
    end

    create_table "discussion_topic_participants" do |t|
      t.integer "discussion_topic_id", :limit => 8
      t.integer "user_id", :limit => 8
      t.integer "unread_entry_count", :default => 0
      t.string "workflow_state"
    end

    add_index "discussion_entry_participants", ["discussion_entry_id", "user_id"], :name => "index_entry_participant_on_entry_id_and_user_id", :unique => true
    add_index "discussion_topic_participants", ["discussion_topic_id", "user_id"], :name => "index_topic_participant_on_topic_id_and_user_id", :unique => true
  end

  def self.down
    drop_table "discussion_entry_participants"
    drop_table "discussion_topic_participants"
  end
end
