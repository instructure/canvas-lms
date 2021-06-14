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
  class DiscussionEntryPermissionsType < ApplicationObjectType
    graphql_name "DiscussionEntryPermissions"

    field :read, Boolean, null: true
    def read
      object[:loader].load(:read)
    end

    field :reply, Boolean, null: true
    def reply
      object[:loader].load(:reply).then do |can_reply|
        can_reply && !object[:discussion_entry].deleted? && object[:discussion_entry].depth < 3
      end
    end

    field :update, Boolean, null: true
    def update
      object[:loader].load(:update)
    end

    field :delete, Boolean, null: true
    def delete
      object[:loader].load(:delete)
    end

    field :create, Boolean, null: true
    def create
      object[:loader].load(:create)
    end

    field :attach, Boolean, null: true
    def attach
      object[:loader].load(:attach)
    end

    field :rate, Boolean, null: true
    def rate
      object[:loader].load(:rate)
    end

    field :view_rating, Boolean, null: true
    def view_rating
      object[:discussion_entry].discussion_topic.allow_rating && !object[:discussion_entry].deleted?
    end
  end
end
