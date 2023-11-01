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

class Mutations::CreateDiscussionEntry < Mutations::BaseMutation
  graphql_name "CreateDiscussionEntry"

  argument :discussion_topic_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionTopic")
  argument :message, String, required: true
  argument :parent_entry_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :file_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Attachment")

  argument :is_anonymous_author, Boolean, required: false
  argument :quoted_entry_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")

  field :discussion_entry, Types::DiscussionEntryType, null: true
  def resolve(input:)
    topic = DiscussionTopic.find(input[:discussion_topic_id])
    raise ActiveRecord::RecordNotFound unless topic.grants_right?(current_user, session, :read)

    association = topic.discussion_entries
    entry = build_entry(association, input[:message], topic, !!input[:is_anonymous_author])

    if input[:parent_entry_id]
      parent_entry = topic.discussion_entries.find(input[:parent_entry_id])
      entry.parent_entry = parent_entry
    end

    if input[:quoted_entry_id] && DiscussionEntry.find(input[:quoted_entry_id])
      entry.quoted_entry_id = input[:quoted_entry_id]
    end

    if input[:file_id]
      attachment = Attachment.find(input[:file_id])
      raise ActiveRecord::RecordNotFound unless attachment.user == current_user

      topic_context = topic.context
      unless topic.grants_right?(current_user, session, :attach) ||
             (topic_context.respond_to?(:allow_student_forum_attachments) &&
               topic_context.allow_student_forum_attachments &&
               topic_context.grants_right?(current_user, session, :post_to_forum) &&
               topic.available_for?(current_user)
             )

        return validation_error(I18n.t("Insufficient attach permissions"))
      end

      entry.attachment = attachment
    end

    entry.save!
    entry.delete_draft

    { discussion_entry: entry }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  rescue InsufficientPermissionsError
    validation_error(I18n.t("Insufficient Permissions"))
  end

  def build_entry(association, message, topic, is_anonymous_author)
    message = Api::Html::Content.process_incoming(message, host: context[:request].host, port: context[:request].port)
    entry = association.build(message:, user: current_user, discussion_topic: topic, is_anonymous_author:)
    raise InsufficientPermissionsError unless entry.grants_right?(current_user, session, :create)

    entry
  end

  class InsufficientPermissionsError < StandardError; end
end
