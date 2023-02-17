# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup::PopulateMissingConversationAndConversationParticipantRootAccountIds
  def self.run
    populate_conversation_root_account_id
    populate_conversation_participant_root_account_id
  end

  def self.populate_conversation_root_account_id
    Conversation.where(root_account_ids: [nil, ""]).each do |convo|
      list_of_ids = convo.conversation_participants.map do |cp|
        cp.user.root_account_ids
      end
      convo.root_account_ids = list_of_ids.flatten.uniq.sort
      convo.save!
    end
  end

  def self.populate_conversation_participant_root_account_id
    ConversationParticipant.where(root_account_ids: [nil, ""]).find_ids_in_batches do |ids|
      ConversationParticipant.where(id: ids).joins(:conversation).update_all("root_account_ids=conversations.root_account_ids")
    end
  end
end
