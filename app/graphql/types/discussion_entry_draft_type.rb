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

module Types
  class DiscussionEntryDraftType < ApplicationObjectType
    graphql_name "DiscussionEntryDraft"

    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface
    global_id_field :id

    field :discussion_topic_id, ID, null: false
    field :discussion_entry_id, ID, null: true
    field :parent_id, ID, null: true
    field :root_entry_id, ID, null: true
    field :message, String, null: false

    field :attachment, Types::FileType, null: true
    def attachment
      load_association(:attachment)
    end
  end
end
