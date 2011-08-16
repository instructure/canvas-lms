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
           :order => "created_at DESC, id DESC", :conditions => 'conversation_id = #{conversation_id}'
           # conditions are redundant, but they let us use the best index

  named_scope :default, :conditions => "workflow_state IN ('read', 'unread')"
  named_scope :unread, :conditions => "workflow_state = 'unread'"
  named_scope :archived, :conditions => "workflow_state = 'archived'"
  named_scope :labeled, lambda { |label|
    {:conditions => label ?
      ["label = ?", label] :
      ["label IS NOT NULL"]
    }
  }
  delegate :private?, :to => :conversation

  before_update :update_unread_count

  attr_accessible :subscribed, :label

  def self.labels
    (@labels ||= {})[I18n.locale] ||= [
      ['red', I18n.t('labels.red', "Red")],
      ['orange', I18n.t('labels.orange', "Orange")],
      ['yellow', I18n.t('labels.yellow', "Yellow")],
      ['green', I18n.t('labels.green', "Green")],
      ['blue', I18n.t('labels.blue', "Blue")],
      ['purple', I18n.t('labels.purple', "Purple")],
    ]
  end

  validates_inclusion_of :label, :in => labels.map(&:first), :allow_nil => true

  def as_json(options = {})
    latest = messages.human.first
    {
      :id => conversation_id,
      :participants => participants(private?),
      :workflow_state => workflow_state,
      :last_message => latest ? truncate_text(latest.body, :max_length => 100) : nil,
      :last_message_at => latest ? latest.created_at : last_message_at,
      :message_count => message_count,
      :subscribed => subscribed?,
      :private => private?,
      :label => label,
      :properties => properties
    }
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

  def participants(include_context_info = true, include_forwarded_participants = false)
    context_info = {}
    self_conversation = conversation.participants == [self.user]
    participants = self_conversation ? conversation.participants : conversation.participants - [self.user]
    if include_forwarded_participants
      user_ids = messages.select{ |m|
        m.forwarded_messages
      }.map{ |m|
        m.forwarded_messages.map(&:author_id)
      }.flatten.uniq - [self.user_id]
      participants |= User.find(:all, :select => User::MESSAGEABLE_USER_COLUMN_SQL + ", NULL AS common_course_ids, NULL AS common_group_ids", :conditions => {:id => user_ids})
    end
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

  def properties
    latest = messages.human.first
    properties = []
    properties << :last_author if latest && latest.author_id == user_id
    properties << :attachments if has_attachments?
    properties << :media_objects if has_media_objects?
    properties
  end

  def add_participants(user_ids)
    conversation.add_participants(user, user_ids)
  end

  def add_message(body, forwarded_message_ids = [])
    conversation.add_message(user, body, false, forwarded_message_ids)
  end

  def remove_messages(*to_delete)
    if to_delete == [:all]
      messages.clear
    else
      messages.delete(*to_delete)
      # if the only messages left are generated ones, e.g. "added
      # bob to the conversation", delete those too
      messages.clear if messages.all?(&:generated?)
    end
    update_cached_data
  end

  def subscribed=(value)
    super
    if subscribed?
      self.workflow_state = :unread
      update_cached_data(false)
    else
      mark_as_read
    end
    subscribed?
  end

  def label=(label)
    write_attribute(:label, label.present? ? label : nil)
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

  private
  def update_cached_data(recalculate_count=true)
    if latest = messages.human.first
      self.message_count = messages.human.size if recalculate_count
      self.last_message_at = latest.created_at
      self.has_attachments = attachments.size > 0
      self.has_media_objects = media_objects.size > 0
    else
      self.workflow_state = 'read' if unread?
      self.message_count = 0
      self.last_message_at = nil
      self.has_attachments = false
      self.has_media_objects = false
    end
    save
  end

  def update_unread_count
    if workflow_state_changed? && [workflow_state, workflow_state_was].include?('unread')
      User.update_all "unread_conversations_count = unread_conversations_count #{workflow_state == 'unread' ? '+' : '-'} 1",
                      :id => user_id
    end
  end
end
