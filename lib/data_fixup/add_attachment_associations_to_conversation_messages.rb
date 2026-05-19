# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module DataFixup
  class AddAttachmentAssociationsToConversationMessages < CanvasOperations::DataFixup
    setting :range_batch_size, default: 100_000, type_cast: :to_i
    self.mode = :batch
    self.progress_tracking = false
    self.batch_strategy = :id

    scope do
      Attachment
        .joins("INNER JOIN #{ConversationMessage.quoted_table_name} ON attachments.id = ANY (string_to_array(conversation_messages.attachment_ids, ',')::INT8[])")
        .where.not(conversation_messages: { attachment_ids: "" })
        .where.not(
          AttachmentAssociation.where("conversation_messages.id = attachment_associations.context_id
                                   and attachment_associations.context_type = 'ConversationMessage'
                                   and attachment_associations.attachment_id = attachments.id").arel.exists
        )
        .select("attachments.id as attachment_id, attachments.root_account_id, conversation_messages.id AS context_id, 'ConversationMessage' AS context_type, null as user_id, null as context_concern")
    end

    def process_batch(attachment_association_data)
      AttachmentAssociation.insert_all(attachment_association_data.map { |a| a.slice(:attachment_id, :root_account_id, :context_id, :context_type, :user_id, :context_concern) })
    end
  end
end
