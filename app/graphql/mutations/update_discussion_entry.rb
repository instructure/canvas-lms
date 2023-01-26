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

class Mutations::UpdateDiscussionEntry < Mutations::BaseMutation
  graphql_name "UpdateDiscussionEntry"

  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")
  argument :message, String, required: false
  argument :remove_attachment, Boolean, required: false
  argument :file_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Attachment")
  argument :include_reply_preview, Boolean, required: false
  argument :quoted_entry_id, ID, required: false

  field :discussion_entry, Types::DiscussionEntryType, null: true
  def resolve(input:)
    entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise ActiveRecord::RecordNotFound unless entry.grants_right?(current_user, session, :read)
    return validation_error(I18n.t("Insufficient Permissions")) unless entry.grants_right?(current_user, session, :update)

    unless input[:message].nil?
      entry.message = Api::Html::Content.process_incoming(input[:message], host: context[:request].host, port: context[:request].port)
    end

    if !input[:remove_attachment].nil? && input[:remove_attachment]
      entry.attachment_id = nil
    end

    if !input[:include_reply_preview].nil? && entry.parent_entry
      entry.include_reply_preview = input[:include_reply_preview]
    end

    if entry.parent_entry
      entry.quoted_entry_id = input[:quoted_entry_id]
    end

    unless input[:file_id].nil?
      attachment = Attachment.find(input[:file_id])
      raise ActiveRecord::RecordNotFound unless attachment.user == current_user

      entry.attachment = attachment
    end

    entry.current_user = current_user
    entry.editor = current_user
    entry.save!
    entry.delete_edit_draft(user_id: current_user.id)

    { discussion_entry: entry }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
