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
  class DiscussionPermissionsType < ApplicationObjectType
    graphql_name "DiscussionPermissions"

    field :read, Boolean, null: true
    def read
      object.load(:read)
    end

    field :read_replies, Boolean, null: true
    def read_replies
      object.load(:read_replies)
    end

    field :reply, Boolean, null: true
    def reply
      object.load(:reply)
    end

    field :update, Boolean, null: true
    def update
      object.load(:update)
    end

    field :delete, Boolean, null: true
    def delete
      object.load(:delete)
    end

    field :create, Boolean, null: true
    def create
      object.load(:create)
    end

    field :duplicate, Boolean, null: true
    def duplicate
      object.load(:duplicate)
    end

    field :attach, Boolean, null: true
    def attach
      object.load(:attach)
    end

    field :read_as_admin, Boolean, null: true
    def read_as_admin
      object.load(:read_as_admin)
    end

    field :rate, Boolean, null: true
    def rate
      object.load(:rate)
    end

    field :moderate_forum, Boolean, null: true
    def moderate_forum
      object.load(:moderate_forum)
    end
  end
end
