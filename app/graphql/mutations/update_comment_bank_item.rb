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

class Mutations::UpdateCommentBankItem < Mutations::BaseMutation
  graphql_name "UpdateCommentBankItem"

  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('CommentBankItem')
  argument :comment, String, required: true

  field :comment_bank_item, Types::CommentBankItemType, null: true

  def resolve(input:)
    record = CommentBankItem.active.find(input[:id])

    verify_authorized_action!(record, :update)

    record.comment = input[:comment]

    return errors_for(record) unless record.save

    {comment_bank_item: record}
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, I18n.t('Record not found')
  end
end
