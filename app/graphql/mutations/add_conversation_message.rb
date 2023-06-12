# frozen_string_literal: true

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
#

class Mutations::AddConversationMessage < Mutations::BaseMutation
  graphql_name "AddConversationMessage"

  include ConversationsHelper

  argument :conversation_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Conversation")
  argument :body, String, required: true
  argument :recipients, [String], required: true
  argument :included_messages, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("ConversationMessage")
  argument :attachment_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Attachment")
  argument :media_comment_id, ID, required: false
  argument :media_comment_type, String, required: false
  argument :context_code, String, required: false
  argument :user_note, Boolean, required: false

  field :conversation_message, Types::ConversationMessageType, null: true

  def resolve(input:)
    conversation = get_conversation(input[:conversation_id])

    message = process_response(
      conversation:,
      context: conversation.conversation.context,
      current_user:,
      session:,
      recipients: input[:recipients],
      context_code: input[:context_code] || conversation.conversation.context&.asset_string || nil,
      message_ids: input[:included_messages],
      body: input[:body],
      attachment_ids: input[:attachment_ids],
      domain_root_account_id: context[:domain_root_account].id,
      media_comment_id: input[:media_comment_id],
      media_comment_type: input[:media_comment_type],
      user_note: input[:user_note]
    )
    InstStatsd::Statsd.increment("inbox.message.sent.isReply.react")
    InstStatsd::Statsd.increment("inbox.message.sent.react")
    InstStatsd::Statsd.count("inbox.message.sent.recipients.react", message[:recipients_count])
    if input[:media_comment_id] || ConversationMessage.where(id: message[:message]&.id).first&.has_media_objects
      InstStatsd::Statsd.increment("inbox.message.sent.media.react")
    end
    if !message[:message].nil? && message[:message][:attachment_ids].present?
      InstStatsd::Statsd.increment("inbox.message.sent.attachment.react")
    end
    { conversation_message: message[:message] }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ConversationsHelper::Error => e
    validation_error(e.message)
  end

  def get_conversation(id)
    conversation = current_user.all_conversations.find_by(conversation_id: id)
    raise ActiveRecord::RecordNotFound unless conversation

    conversation
  end
end
