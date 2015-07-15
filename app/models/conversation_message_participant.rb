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

class ConversationMessageParticipant < ActiveRecord::Base
  include SimpleTags
  include Workflow

  belongs_to :conversation_message
  belongs_to :user
  # deprecated
  belongs_to :conversation_participant
  delegate :author, :author_id, :generated, :body, :to => :conversation_message

  attr_accessible

  EXPORTABLE_ATTRIBUTES = [:id, :conversation_message_id, :conversation_participant_id, :tags, :user_id, :workflow_state]
  EXPORTABLE_ASSOCIATIONS = [:conversation_message, :user, :conversation_participant]

  scope :active, -> { where("(conversation_message_participants.workflow_state <> 'deleted' OR conversation_message_participants.workflow_state IS NULL)") }
  scope :deleted, -> { where(workflow_state: 'deleted') }

  scope :for_conversation_and_message, lambda { |conversation_id, message_id|
    joins(:conversation_participant).
        where(:conversation_id => conversation_id, :conversation_message_id => message_id)
  }

  workflow do
    state :active
    state :deleted
  end

end
