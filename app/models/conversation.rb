#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class Conversation < ActiveRecord::Base
  has_many :conversation_participants
  has_many :subscribed_conversation_participants,
           :conditions => "subscribed",
           :class_name => 'ConversationParticipant'
  has_many :conversation_messages, :order => "created_at DESC, id DESC"

  # see also User#messageable_users
  has_many :participants,
    :through => :conversation_participants,
    :source => :user,
    :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_courses, NULL AS common_groups",
    :order => 'last_authored_at IS NULL, last_authored_at DESC, LOWER(COALESCE(short_name, name))'
  has_many :subscribed_participants,
    :through => :subscribed_conversation_participants,
    :source => :user,
    :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_courses, NULL AS common_groups",
    :order => 'last_authored_at IS NULL, last_authored_at DESC, LOWER(COALESCE(short_name, name))'
  has_many :attachments, :through => :conversation_messages

  attr_accessible

  def private?
    private_hash.present?
  end

  def self.initiate(user_ids, private)
    private_hash = private ? Digest::SHA1.hexdigest(user_ids.sort.join(',')) : nil
    transaction do
      unless private_hash && conversation = find_by_private_hash(private_hash)
        conversation = new
        conversation.private_hash = private_hash
        conversation.has_attachments = false
        conversation.has_media_objects = false
        conversation.save!
        user_ids.each do |user_id|
          participant = conversation.conversation_participants.build
          participant.user_id = user_id
          participant.save!
        end
        User.update_all('unread_conversations_count = unread_conversations_count + 1', :id => user_ids)
      end
      conversation
    end
  end

  def add_participants(current_user, user_ids)
    user_ids.map!(&:to_i)
    raise "can't add participants to a private conversation" if private?
    transaction do
      lock!
      user_ids -= conversation_participants.map(&:user_id)
      next if user_ids.empty?

      User.update_all('unread_conversations_count = unread_conversations_count + 1', :id => user_ids)

      last_message_at = conversation_messages.human.first.created_at
      num_messages = conversation_messages.human.size
      user_ids.each do |user_id|
        participant = conversation_participants.build
        participant.user_id = user_id
        participant.last_message_at = last_message_at
        participant.message_count = num_messages
        participant.save!
      end

      # give them all messages
      connection.execute(<<-SQL)
        INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id)
        SELECT conversation_messages.id, conversation_participants.id
        FROM conversation_messages, conversation_participants
        WHERE conversation_messages.conversation_id = #{self.id}
          AND conversation_messages.conversation_id = conversation_participants.conversation_id
          AND conversation_participants.user_id IN (#{user_ids.join(', ')})
      SQL

      # announce their arrival
      add_event_message(current_user, :event_type => :users_added, :user_ids => user_ids)
    end
  end

  def add_event_message(current_user, event_data={})
    add_message(current_user, event_data.to_yaml, :generated => true)
  end

  def add_message(current_user, body, options = {})
    options = {:generated => false,
               :forwarded_message_ids => [],
               :update_for_sender => true}.update(options)
    transaction do
      lock!

      message = conversation_messages.build
      message.author_id = current_user.id
      message.body = body
      message.generated = options[:generated]
      message.context = options[:context]
      if options[:forwarded_message_ids].present?
        messages = ConversationMessage.find_all_by_id(options[:forwarded_message_ids].map(&:to_i))
        conversation_ids = messages.map(&:conversation_id).uniq
        raise "can only forward one conversation at a time" if conversation_ids.size != 1
        raise "user doesn't have permission to forward these messages" unless current_user.conversations.find_by_conversation_id(conversation_ids.first)
        # TODO: optimize me
        message.forwarded_message_ids = messages.map(&:id).join(',')
      end
      message.save!

      yield message if block_given?

      connection.execute(<<-SQL)
        INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id)
        SELECT #{message.id}, id FROM conversation_participants WHERE conversation_id = #{id}
      SQL

      unless options[:generated]
        connection.execute("UPDATE conversation_participants SET message_count = message_count + 1 WHERE conversation_id = #{id}")

        # make sure this jumps to the top of the inbox and is marked as unread for anyone who's subscribed
        cp_conditions = self.class.send :sanitize_sql_array, [
          "cp.conversation_id = ? AND cp.workflow_state <> 'unread' AND (cp.last_message_at IS NULL OR cp.subscribed) AND cp.user_id <> ?",
          self.id,
          current_user.id
        ]
        if connection.adapter_name =~ /mysql/i
          connection.execute <<-SQL
            UPDATE users, conversation_participants cp
            SET unread_conversations_count = unread_conversations_count + 1
            WHERE users.id = cp.user_id AND #{cp_conditions}
          SQL
        else
          User.update_all 'unread_conversations_count = unread_conversations_count + 1',
                          "id IN (SELECT user_id FROM conversation_participants cp WHERE #{cp_conditions})"
        end
        conversation_participants.update_all(
          {:last_message_at => Time.now.utc, :workflow_state => 'unread'},
          ["(last_message_at IS NULL OR subscribed) AND user_id <> ?", current_user.id]
        )

        # for the sender, update the timestamps
        # marking it as read is a ui concern, unless it's the first message (e.g. we might be sending from outside the inbox)
        if (sender_conversation = conversation_participants.find_by_user_id(current_user.id)) && (options[:update_for_sender] || sender_conversation.last_message_at)
          mark_as_read = options[:update_for_sender] && sender_conversation.last_message_at.nil?
          if mark_as_read && sender_conversation.unread? && sender_conversation.last_message_at 
            User.update_all 'unread_conversations_count = unread_conversations_count - 1', :id => current_user.id
          end
          sender_conversation.last_message_at = Time.now.utc
          sender_conversation.last_authored_at = Time.now.utc
          sender_conversation.workflow_state = 'read' if mark_as_read
          sender_conversation.save
        end
  
        updated = false
        if message.attachments.present?
          self.has_attachments = true
          conversation_participants.update_all({:has_attachments => true}, "NOT has_attachments")
          updated = true
        end
        if message.media_comment_id.present?
          self.has_media_objects = true
          conversation_participants.update_all({:has_media_objects => true}, "NOT has_media_objects")
          updated = true
        end
        self.save if updated
      end
      
      message
    end
  end

  def reply_from(opts)
    user = opts.delete(:user)
    message = opts.delete(:text).to_s.strip
    user = nil unless user && self.participants.find_by_id(user.id)
    if !user
      raise "Only message participants may reply to messages"
    elsif message.blank?
      raise "Message body cannot be blank"
    else
      add_message(user, message, opts)
    end
  end
end
