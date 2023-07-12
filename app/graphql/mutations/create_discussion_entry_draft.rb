# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Mutations::CreateDiscussionEntryDraft < Mutations::BaseMutation
  graphql_name "CreateDiscussionEntryDraft"

  argument :discussion_topic_id,
           ID,
           required: true,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionTopic")
  argument :discussion_entry_id,
           ID,
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :parent_id,
           ID,
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :file_id,
           ID,
           required: false,
           prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Attachment")
  argument :message, String, required: true

  field :discussion_entry_draft, Types::DiscussionEntryDraftType, null: true

  def resolve(input:)
    topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise ActiveRecord::RecordNotFound unless topic.grants_right?(current_user, session, :read)
    raise InsufficientPermissionsError unless topic.grants_right?(current_user, session, :reply)

    entry, parent_entry, attachment = nil
    if input[:parent_id]
      parent_entry = topic.discussion_entries.active.find(input[:parent_id])
    end

    if input[:discussion_entry_id]
      entry = topic.discussion_entries.active.find(input[:discussion_entry_id])
    end

    if input[:file_id]
      attachment = Attachment.find(input[:file_id])
      raise ActiveRecord::RecordNotFound unless attachment.user == current_user
    end

    message = Api::Html::Content.process_incoming(input[:message],
                                                  host: context[:request].host,
                                                  port: context[:request].port)

    id = DiscussionEntryDraft.upsert_draft(user: current_user,
                                           message:,
                                           topic:,
                                           entry:,
                                           parent: parent_entry,
                                           attachment:).first
    draft = DiscussionEntryDraft.new(
      id:,
      message:,
      discussion_topic_id: topic.id,
      discussion_entry_id: entry&.id,
      parent_id: parent_entry&.id,
      root_entry_id: parent_entry&.root_entry_id || parent_entry&.id,
      updated_at: Time.zone.now,
      created_at: Time.zone.now
    )
    draft.readonly!

    { discussion_entry_draft: draft }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue InsufficientPermissionsError
    validation_error(I18n.t("Insufficient Permissions"))
  end

  class InsufficientPermissionsError < StandardError; end
end
