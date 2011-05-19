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

  belongs_to :conversation
  belongs_to :user
  has_many :conversation_message_participants
  has_many :messages, :source => :conversation_message, :through => :conversation_message_participants,
           :order => "created_at DESC", :conditions => 'conversation_id = #{conversation_id}'
           # conditions are redundant, but they let us use the best index

  delegate :participants, :to => :conversation

  named_scope :default, :conditions => "workflow_state IN ('read', 'unread')"
  named_scope :unread, :conditions => "workflow_state = 'unread'"
  named_scope :archived, :conditions => "workflow_state = 'archived'"

  attr_accessible :subscribed

  def add_participants(user_ids)
    conversation.add_participants(user, user_ids)
  end

  def add_message(body)
    conversation.add_message(user, body)
  end

  def update_last_message_at
    self.last_message_at = self.messages.last ? self.messages.last.created_at : nil
    save
  end

  def subscribed=(value)
    super
    subscribed? ? mark_as_unread : mark_as_read
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