# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class Mutations::RestoreDeletedDiscussionEntry < Mutations::BaseMutation
  argument :discussion_entry_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("DiscussionEntry")

  field :discussion_entry, Types::DiscussionEntryType, null: true

  def resolve(input:)
    entry = DiscussionEntry.find(input[:discussion_entry_id])
    raise ActiveRecord::RecordNotFound unless entry.grants_right?(current_user, session, :read)
    return validation_error(I18n.t("Insufficient Permissions")) unless entry.grants_right?(current_user, session, :update)

    if entry.deleted?
      entry.restore
      { discussion_entry: entry }
    else
      validation_error(I18n.t("Discussion entry is not deleted"))
    end
  end
end
