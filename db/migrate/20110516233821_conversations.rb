class Conversations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table "conversations" do |t|
      t.string "private_hash" # for quick lookups so we know whether or not we need to create a new one
    end
    add_index "conversations", ["private_hash"], :unique => true

    create_table "conversation_participants" do |t|
      t.integer  "conversation_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.datetime "last_message_at"
      t.boolean  "subscribed", :default => true
      t.string   "workflow_state"
    end
    add_index "conversation_participants", ["conversation_id"]
    add_index "conversation_participants", ["user_id", "last_message_at"]

    create_table "conversation_messages" do |t|
      t.integer  "conversation_id", :limit => 8
      t.integer  "author_id", :limit => 8
      t.datetime "created_at"
      t.boolean  "generated"
      t.text     "body"
    end
    add_index "conversation_messages", ["conversation_id", "created_at"]

    create_table "conversation_message_participants" do |t|
      t.integer  "conversation_message_id", :limit => 8
      t.integer  "conversation_participant_id", :limit => 8
    end
  end

  def self.down
    drop_table "conversations"
    drop_table "conversation_participants"
    drop_table "conversation_messages"
    drop_table "conversation_message_participants"
  end
end
