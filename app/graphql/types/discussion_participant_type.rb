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
  class DiscussionParticipantType < ApplicationObjectType
    graphql_name "DiscussionParticipant"

    global_id_field :id

    field :expanded, Boolean, null: true
    def expanded
      object.discussion_topic.expanded_for_user(current_user)
    end

    field :read, Boolean, null: false
    def read_status
      object.workflow_state == "read"
    end
    alias_method :read, :read_status

    field :sort_order, Types::DiscussionSortOrderType, null: true
    def sort_order
      object.discussion_topic.sort_order_for_user(current_user).to_sym
    end

    field :summary_enabled, Boolean, null: true
    field :workflow_state, String, null: false

    field :discussion_topic, Types::DiscussionType, null: false
    def discussion_topic
      load_association(:discussion_topic)
    end
  end
end
