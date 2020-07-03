#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsOnConversationsTables
  def self.run(min, max)
    Conversation.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      ConversationParticipant.joins(:conversation).
        where(conversation: batch_min..batch_max).
        update_all("root_account_ids=conversations.root_account_ids")

      messages = ConversationMessage.joins(:conversation).where(conversation: batch_min..batch_max)
      messages.update_all("root_account_ids=conversations.root_account_ids")

      # only has FK to ConversationMessage and ConversationParticipant, not Conversation
      ConversationMessageParticipant.joins(:conversation_message).
        where(conversation_message: messages).
        update_all("root_account_ids=conversation_messages.root_account_ids")
    end
  end
end