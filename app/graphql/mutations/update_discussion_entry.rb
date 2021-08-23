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
  graphql_name 'UpdateDiscussionEntry'

  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('DiscussionEntry')
  argument :message, String, required: false
  argument :remove_attachment, Boolean, required: false
  argument :file_id, ID, required: false, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('Attachment')

  field :discussion_entry, Types::DiscussionEntryType, null: true
  def resolve(input:)
    entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise ActiveRecord::RecordNotFound unless entry.grants_right?(current_user, session, :read)
    return validation_error(I18n.t('Insufficient Permissions')) unless entry.grants_right?(current_user, session, :update)

    unless input[:message].nil?
      entry.message = Api::Html::Content.process_incoming(input[:message], host: context[:request].host, port: context[:request].port)
    end

    unless input[:remove_attachment].nil?
      entry.attachment_id = nil if input[:remove_attachment]
    end

    unless input[:file_id].nil?
      attachment = Attachment.find(input[:file_id])
      raise ActiveRecord::RecordNotFound unless attachment.user == current_user

      entry.attachment = attachment
    end

    entry.current_user = current_user
    entry.editor = current_user
    entry.save!

    {discussion_entry: entry}
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  end
end
