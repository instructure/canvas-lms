#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::FixBulkMessageAttachments
  def self.run
    ConversationBatch.preload(:root_conversation_message).find_each do |batch|
      root_message = batch.root_conversation_message
      next unless root_message.has_attachments?
      messages = ConversationMessage.find(batch.conversation_message_ids)
      messages.each do |message|
        message.attachment_ids = root_message.attachment_ids
        message.save!
      end
    end
  end
end
