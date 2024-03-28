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

class Mutations::CreateConversation < Mutations::BaseMutation
  graphql_name "CreateConversation"

  include ConversationsHelper

  argument :recipients, [String], required: true
  argument :subject, String, required: false
  argument :body, String, required: true
  argument :bulk_message, Boolean, required: false
  argument :force_new, Boolean, required: false
  argument :group_conversation, Boolean, required: false
  argument :attachment_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Attachment")
  argument :media_comment_id, ID, required: false
  argument :media_comment_type, String, required: false
  argument :context_code, String, required: false
  argument :conversation_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Conversation")
  argument :user_note, Boolean, required: false
  argument :tags, [String], required: false

  field :conversations, [Types::ConversationParticipantType], null: true
  def resolve(input:)
    @current_user = current_user
    recipients = get_recipients(input[:recipients], input[:context_code], input[:conversation_id])
    tags = infer_tags(tags: input[:tags], recipients: input[:recipients], context_code: input[:context_code])

    context = input[:context_code] ? Context.find_by_asset_string(input[:context_code]) : nil
    validate_context(context, recipients) if context
    context_type = context&.class&.name
    context_id = context&.id
    shard = context ? context.shard : Shard.current

    if context.blank? && !@current_user.associated_root_accounts.first.try(:grants_right?, @current_user, session, :read_roster)
      return validation_error(
        I18n.t("Context cannot be blank"),
        attribute: "context_code"
      )
    end

    group_conversation = input[:group_conversation]
    batch_private_messages = !group_conversation && recipients.size > 1
    batch_group_messages = (group_conversation && input[:bulk_message]) || input[:force_new]
    message = Conversation.build_message(*build_message_args(
      body: input[:body],
      attachment_ids: input[:attachment_ids],
      domain_root_account_id: self.context[:domain_root_account].id,
      media_comment_id: input[:media_comment_id],
      media_comment_type: input[:media_comment_type],
      user_note: input[:user_note]
    ))

    if !batch_group_messages && recipients.size > Conversation.max_group_conversation_size
      return validation_error(
        I18n.t("Too many recipients for group conversation"),
        attribute: "recipients"
      )
    end

    shard.activate do
      if batch_private_messages || batch_group_messages
        message.relativize_attachment_ids(from_shard: message.shard, to_shard: shard)
        message.shard = shard
        batch = ConversationBatch.generate(
          message,
          recipients,
          (recipients.size > Conversation.max_group_conversation_size) ? :async : :sync,
          subject: input[:subject],
          context_type:,
          context_id:,
          tags:,
          group: batch_group_messages
        )

        # reload and preload stuff
        conversations = ConversationParticipant.where(id: batch.conversations)
                                               .preload(:conversation)
                                               .order("visible_last_authored_at DESC, last_message_at DESC, id DESC")
        Conversation.preload_participants(conversations.map(&:conversation))
        ConversationParticipant.preload_latest_messages(conversations, @current_user)
        InstStatsd::Statsd.increment("inbox.message.sent.react")
        InstStatsd::Statsd.count("inbox.conversation.created.react", conversations.count)
        InstStatsd::Statsd.increment("inbox.conversation.sent.react")
        InstStatsd::Statsd.count("inbox.message.sent.recipients.react", recipients.count)
        if context_type == "Account" || context_type.nil?
          InstStatsd::Statsd.increment("inbox.conversation.sent.account_context.react")
        end
        if message.has_media_objects || input[:media_comment_id]
          InstStatsd::Statsd.increment("inbox.message.sent.media.react")
        end
        if message[:attachment_ids].present?
          InstStatsd::Statsd.increment("inbox.message.sent.attachment.react")
        end
        if !Account.site_admin.feature_enabled?(:deprecate_faculty_journal) && input[:user_note]
          InstStatsd::Statsd.increment("inbox.conversation.sent.faculty_journal.react")
        end
        if input[:bulk_message]
          InstStatsd::Statsd.increment("inbox.conversation.sent.individual_message_option.react")
        end
        return { conversations: }
      else
        conversation = @current_user.initiate_conversation(
          recipients,
          !group_conversation,
          subject: input[:subject],
          context_type:,
          context_id:
        )
        conversation.add_message(
          message,
          tags:,
          update_for_sender: false,
          cc_author: true
        )
        InstStatsd::Statsd.increment("inbox.conversation.created.react")
        InstStatsd::Statsd.increment("inbox.message.sent.react")
        InstStatsd::Statsd.increment("inbox.conversation.sent.react")
        InstStatsd::Statsd.count("inbox.message.sent.recipients.react", recipients.count)
        if message.has_media_objects || input[:media_comment_id]
          InstStatsd::Statsd.increment("inbox.message.sent.media.react")
        end
        if message[:attachment_ids].present?
          InstStatsd::Statsd.increment("inbox.message.sent.attachment.react")
        end
        if context_type == "Account" || context_type.nil?
          InstStatsd::Statsd.increment("inbox.conversation.sent.account_context.react")
        end
        if !Account.site_admin.feature_enabled?(:deprecate_faculty_journal) && input[:user_note]
          InstStatsd::Statsd.increment("inbox.conversation.sent.faculty_journal.react")
        end
        if input[:bulk_message]
          InstStatsd::Statsd.increment("inbox.conversation.sent.individual_message_option.react")
        end
        return { conversations: [conversation] }
      end
    end
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue ActiveRecord::RecordInvalid => e
    errors_for(e.record)
  rescue ConversationsHelper::InvalidContextError
    validation_error(
      I18n.t(
        "No context found for the following context code: %{context_code}",
        { context_code: input[:context_code] }
      ),
      attribute: "context_code"
    )
  rescue ConversationsHelper::InvalidContextPermissionsError
    validation_error(
      I18n.t(
        "Unable to send messages to users in %{context_name}",
        { context_name: context.name }
      ),
      attribute: "permissions"
    )
  rescue ConversationsHelper::CourseConcludedError
    validation_error(I18n.t("Course concluded, unable to send messages"))
  rescue ConversationsHelper::InvalidRecipientsError
    validation_error(I18n.t("Invalid recipients"))
  end

  def get_recipients(recipient_ids, context_code, conversation_id)
    recipients = normalize_recipients(recipients: recipient_ids, context_code:, conversation_id:)
    raise ConversationsHelper::InvalidRecipientsError if recipients.blank?

    recipients
  end
end
