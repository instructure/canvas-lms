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
  has_many :conversation_messages, :order => "created_at DESC"

  # see also User#messageable_users
  has_many :participants,
    :through => :conversation_participants,
    :source => :user,
    :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_course_ids, NULL AS common_group_ids",
    :order => 'last_authored_at DESC, LOWER(COALESCE(short_name, name))'
  has_many :subscribed_participants,
    :through => :subscribed_conversation_participants,
    :source => :user,
    :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_course_ids, NULL AS common_group_ids",
    :order => 'last_authored_at DESC, LOWER(COALESCE(short_name, name))'
  has_many :attachments, :through => :conversation_messages
  has_many :media_objects, :through => :conversation_messages

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

      last_message_at = conversation_messages.human.first.created_at
      user_ids.each do |user_id|
        participant = conversation_participants.build
        participant.user_id = user_id
        participant.last_message_at = last_message_at
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
    add_message(current_user, event_data.to_yaml, true)
  end

  def add_message(current_user, body, generated = false)
    transaction do
      lock!

      message = conversation_messages.build
      message.author_id = current_user.id
      message.body = body
      message.generated = generated
      message.save!

      # TODO: attachments and media comments


      connection.execute(<<-SQL)
        INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id)
        SELECT #{message.id}, id FROM conversation_participants WHERE conversation_id = #{id}
      SQL

      unless generated
        # make sure this jumps to the top of the inbox and is marked as unread for anyone who's subscribed
        conversation_participants.update_all(
          {:last_message_at => Time.now.utc, :workflow_state => 'unread'},
          ["(last_message_at IS NULL OR subscribed) AND user_id <> ?", current_user.id]
        )
        # for the sender, auto-mark as 'read', and update the last_authored_at
        conversation_participants.update_all(
          {:last_message_at => Time.now.utc, :workflow_state => 'read', :last_authored_at => Time.now.utc},
          ["user_id = ?", current_user.id]
        )
  
        conversation_participants.update_all({:has_attachments => true}, "NOT has_attachments") if message.attachments
        conversation_participants.update_all({:has_media_objects => true}, "NOT has_media_objects") if message.media_objects
      end
      
      message
    end
  end
end
