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

class Mutations::DeleteDiscussionEntry < Mutations::BaseMutation
  graphql_name 'DeleteDiscussionEntry'

  argument :id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func('DiscussionEntry')

  # Due to the way we represent deleted discussion entries we are diverging from
  # the convention of only returning deleted record ids. This is intentional and
  # facilitates the representation of deleted discussion entries in the UI.
  field :discussion_entry, Types::DiscussionEntryType, null: true
  def resolve(input:)
    entry = DiscussionEntry.find(input[:id])
    raise GraphQL::ExecutionError, 'not found' unless entry.grants_right?(current_user, session, :read)
    return validation_error(I18n.t('Insufficient permissions')) unless entry.grants_right?(current_user, session, :delete)

    entry.destroy
    {discussion_entry: entry}
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, 'not found'
  end
end
