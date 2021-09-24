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

class Mutations::DeleteCommentBankItem < Mutations::BaseMutation
  graphql_name "DeleteCommentBankItem"

  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('CommentBankItem')
  field :comment_bank_item_id, ID, null: false

  def resolve(input:)
    record = CommentBankItem.active.find_by(id: input[:id])
    raise GraphQL::ExecutionError, I18n.t('Unable to find CommentBankItem') if record.nil?

    verify_authorized_action!(record, :delete)
    context[:deleted_models][:comment_bank_item] = record

    if record.destroy
      {comment_bank_item_id: record.id}
    else
      raise GraphQL::ExecutionError, I18n.t('Unable to delete CommentBankItem')
    end
  end

  def self.comment_bank_item_id_log_entry(_entry, context)
    context[:deleted_models][:comment_bank_item]
  end
end
