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

class ConversationParticipant < ActiveRecord::Base
  include Workflow
  include TextHelper

  belongs_to :conversation
  belongs_to :user
  has_many :conversation_message_participants
  has_many :messages, :source => :conversation_message, :through => :conversation_message_participants,
           :order => "created_at DESC", :conditions => 'conversation_id = #{conversation_id}'
           # conditions are redundant, but they let us use the best index

  named_scope :default, :conditions => "workflow_state IN ('read', 'unread')"
  named_scope :unread, :conditions => "workflow_state = 'unread'"
  named_scope :archived, :conditions => "workflow_state = 'archived'"
  delegate :private?, :to => :conversation

  attr_accessible :subscribed

  def as_json(options = {})
    latest = messages.human.first
    super.merge(
      :id => id,
      :participants => participants(private?),
      :workflow_state => workflow_state,
      :last_message => latest ? truncate_text(latest.body, :max_length => 100) : nil,
      :last_message_at => last_message_at,
      :subscribed => subscribed?,
      :private => private?,
      :flags => flags
    )
  end

  [:attachments, :media_objects].each do |association|
    class_eval <<-ASSOC
      def #{association}
        @#{association} ||= conversation.#{association}.scoped(:conditions => <<-SQL)
          EXISTS (
            SELECT 1
            FROM conversation_message_participants
            WHERE conversation_participant_id = \#{user_id}
              AND conversation_message_id = conversation_messages.id
          )
          SQL
      end
    ASSOC
  end

  def participants(include_context_info = true)
    context_info = {}
    participants = conversation.participants - [self.user]
    return participants unless include_context_info
    # we do this to find out the contexts they share with the user
    user.messageable_users(:ids => participants.map(&:id), :no_check_context => true).each { |user|
      context_info[user.id] = user
    }
    participants.each { |user|
      user.common_course_ids = context_info[user.id].common_course_ids
      user.common_group_ids = context_info[user.id].common_group_ids
    }
  end

  def infer_defaults
    self.has_attachments = conversation.has_attachments?
    self.has_media_objects = conversation.has_media_objects?
  end

  def flags
    latest = messages.human.first
    flags = []
    flags << :last_author if latest && latest.author_id == user_id
    flags << :attachments if has_attachments?
    flags << :media_objects if has_media_objects?
    flags
  end

  def add_participants(user_ids)
    conversation.add_participants(user, user_ids)
  end

  def add_message(body)
    conversation.add_message(user, body)
  end

  def update_cached_data
    if latest = messages.human.first
      self.last_message_at = latest.created_at
      self.has_attachments = attachments.size > 0
      self.has_media_objects = media_objects.size > 0
    else
      self.last_message_at = nil
      self.has_attachments = false
      self.has_media_objects = false
    end
    save
  end

  def subscribed=(value)
    super
    if subscribed?
      self.workflow_state = :unread
      update_cached_data
    else
      mark_as_read
    end
    subscribed?
  end

  workflow do
    state :unread do
      event :mark_as_read, :transitions_to => :read
      event :archive, :transitions_to => :archived
    end
    state :read do
      event :mark_as_unread, :transitions_to => :unread
      event :archive, :transitions_to => :archived
    end
    state :archived do
      event :unarchive, :transitions_to => :read
    end
  end
end
