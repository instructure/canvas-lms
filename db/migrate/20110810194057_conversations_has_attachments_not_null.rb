class ConversationsHasAttachmentsNotNull < ActiveRecord::Migration
  def self.up
    [:conversations, :conversation_participants].each do |table|
      [:has_attachments, :has_media_objects].each do |column|
        change_column_null table, column, false, false
        change_column_default table, column, false
      end
    end
  end

  def self.down
    [:conversations, :conversation_participants].each do |table|
      [:has_attachments, :has_media_objects].each do |column|
        change_column_null table, column, true
        change_column_default table, column, nil
      end
    end
  end
end
