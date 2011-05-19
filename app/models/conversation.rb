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
  has_many :conversation_messages
  has_many :participants, :through => :conversation_participants, :source => :user

  attr_accessible :private_hash

  def private?
    private_hash.present?
  end

  def self.initiate(user_ids, private)
    private_hash = private ? Digest::SHA1.hexdigest(user_ids.sort.join(',')) : nil
    transaction do
      unless private_hash && conversation = find_by_private_hash(private_hash)
        conversation = create(:private_hash => private_hash)
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

      user_ids.each do |user_id|
        participant = conversation_participants.build
        participant.user_id = user_id
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
      add_message(current_user, "#{User.find(user_ids).map(&:name).to_sentence} #{user_ids.size > 1 ? "were": "was"} added to the conversation by #{current_user.name}", true)
    end
  end

  def add_message(current_user, body, generated = false)
    transaction do
      lock!

      message = conversation_messages.build
      message.author_id = current_user.id
      message.body = body
      message.generated = generated
      message.save!

      connection.execute(<<-SQL)
        INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id)
        SELECT #{message.id}, id FROM conversation_participants WHERE conversation_id = #{id}
      SQL

      # make sure this jumps to the top of the inbox and is marked as unread for anyone who's subscribed
      # (for the sender, auto-mark as 'read')
      connection.execute(<<-SQL)
        UPDATE conversation_participants SET last_message_at = NOW(),
          workflow_state = CASE WHEN user_id = #{current_user.id} THEN 'read' ELSE 'unread' END
        WHERE conversation_id = #{id} AND (last_message_at IS NULL OR subscribed)
      SQL

      message
    end
  end
end