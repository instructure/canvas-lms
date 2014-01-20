class AddForeignKeys11 < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :submission_comment_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :submission_comments, :users, column: :author_id, delay_validation: true
    add_foreign_key_if_not_exists :submission_comments, :users, column: :recipient_id, delay_validation: true
    add_foreign_key_if_not_exists :submissions, :users, delay_validation: true
    add_foreign_key_if_not_exists :user_notes, :users, column: :created_by_id, delay_validation: true
    add_foreign_key_if_not_exists :user_notes, :users, delay_validation: true
    add_foreign_key_if_not_exists :web_conference_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :web_conferences, :users, delay_validation: true
    add_foreign_key_if_not_exists :wiki_pages, :users, delay_validation: true
    add_foreign_key_if_not_exists :conversation_messages, :conversations, delay_validation: true
    add_foreign_key_if_not_exists :conversation_message_participants, :conversation_messages, delay_validation: true
    add_foreign_key_if_not_exists :conversation_batches, :conversation_messages, column: :root_conversation_message_id, delay_validation: true
    add_foreign_key_if_not_exists :conversation_batches, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :submission_comment_participants, :users
    remove_foreign_key_if_exists :submission_comments, column: :author_id
    remove_foreign_key_if_exists :submission_comments, column: :recipient_id
    remove_foreign_key_if_exists :submissions, :users
    remove_foreign_key_if_exists :user_notes, column: :created_by_id
    remove_foreign_key_if_exists :user_notes, :users
    remove_foreign_key_if_exists :web_conference_participants, :users
    remove_foreign_key_if_exists :web_conferences, :users
    remove_foreign_key_if_exists :wiki_pages, :users
    remove_foreign_key_if_exists :conversation_messages, :conversations
    remove_foreign_key_if_exists :conversation_message_participants, :conversation_messages
    remove_foreign_key_if_exists :conversation_batches, column: :root_conversation_message_id
    remove_foreign_key_if_exists :conversation_batches, :users
  end
end
