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
  graphql_name 'AddConversationMessage'

  include ConversationsHelper

  argument :conversation_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Conversation')
  argument :body, String, required: true
  argument :recipients, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('User')
  argument :included_messages, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('ConversationMessage')
  argument :attachment_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func('Attachment')
  argument :media_comment_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('MediaObject')
  argument :media_comment_type, String, required: false
  argument :user_note, Boolean, required: false

  field :conversation_message, Types::ConversationMessageType, null: true
  field :message_queued, Boolean, null: true
  # TODO: VICE-1037 logic is mostly duplicated in ConversationsController
  def resolve(input:)
    conversation = get_conversation(input[:conversation_id])

    context = conversation.conversation.context
    if context.is_a?(Course) && context.workflow_state == 'completed' && !context.grants_right?(current_user, session, :read_as_admin)
      return validation_error(I18n.t('Course concluded, unable to send messages'))
    end

    if conversation.conversation.replies_locked_for?(current_user)
      return validation_error(I18n.t('Unauthorized, unable to add messages to conversation'))
    end

    recipients = normalize_recipients(
      recipients: input[:recipients],
      context_code: conversation.conversation.context.asset_string,
      conversation_id: conversation.conversation_id,
      current_user: current_user
    )
    if recipients && !conversation.conversation.can_add_participants?(recipients)
      return validation_error(I18n.t('Too many participants for group conversation'))
    end

    tags = infer_tags(
      recipients: conversation.conversation.participants.pluck(:id),
      context_code: conversation.conversation.context.asset_string
    )

    message_ids = input[:included_messages]
    validate_message_ids(message_ids, conversation, current_user: current_user)

    message_args = build_message_args(
      body: input[:body],
      attachment_ids: input[:attachment_ids],
      domain_root_account_id: self.context[:domain_root_account].id,
      media_comment_id: input[:media_comment_id],
      media_comment_type: input[:media_comment_type],
      user_note: input[:user_note],
      current_user: current_user
    )
    if conversation.should_process_immediately?
      message = conversation.process_new_message(message_args, recipients, message_ids, tags)
      return {conversation_message: message}
    else
      conversation.delay(strand: "add_message_#{conversation.global_conversation_id}").
        process_new_message(message_args, recipients, message_ids, tags)
      return {message_queued: true}
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ConversationsHelper::InvalidMessageForConversationError
    validation_error(I18n.t('included_messages not for this conversation'))
  rescue ConversationsHelper::InvalidMessageParticipantError
    validation_error('Current user is not a participant of the included_messages')
  end

  def get_conversation(id)
    conversation = current_user.all_conversations.find_by(conversation_id: id)
    raise ActiveRecord::RecordNotFound unless conversation

    conversation
  end
end