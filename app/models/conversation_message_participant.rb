# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include ConversationHelper

  belongs_to :conversation_message
  belongs_to :user
  # deprecated
  belongs_to :conversation_participant
  delegate :author, :author_id, :generated, :body, to: :conversation_message

  before_create :set_root_account_ids

  scope :active, -> { where("(conversation_message_participants.workflow_state <> 'deleted' OR conversation_message_participants.workflow_state IS NULL)") }
  scope :deleted, -> { where(workflow_state: "deleted") }

  scope :for_conversation_and_message, lambda { |conversation_id, message_id|
    joins(:conversation_participant)
      .where(conversation_id:, conversation_message_id: message_id)
  }

  workflow do
    state :active
    state :deleted
  end

  delegate :conversation, to: :conversation_message

  def self.query_deleted(user_id, options = {})
    query = deleted.eager_load(:conversation_message).where(user_id:).order(deleted_at: :desc)

    query = query.where(conversation_messages: { conversation_id: options["conversation_id"] }) if options["conversation_id"]
    query = query.where("conversation_message_participants.deleted_at < ?", options["deleted_before"]) if options["deleted_before"]
    query = query.where("conversation_message_participants.deleted_at > ?", options["deleted_after"]) if options["deleted_after"]

    query
  end
end
