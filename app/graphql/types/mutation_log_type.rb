# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class MutationLogType < ApplicationObjectType
    field :asset_string, ID, null: false, hash_key: :object_id
    def asset_string
      # strip the domain-root-account prefix
      object["object_id"].split("-", 2).last
    end

    field :mutation_id, ID, null: false

    field :mutation_name, String, null: false

    field :timestamp, DateTimeType, null: true
    def timestamp
      object["timestamp"] && Time.zone.iso8601(object["timestamp"])
    rescue ArgumentError
      nil
    end

    field :user, UserType, null: true
    def user
      Loaders::IDLoader.for(User).load(object["current_user_id"])
    end

    field :real_user, UserType, <<~DOC, null: true
      If the mutation was performed by a user masquerading as another user,
      this field returns the "real" (logged-in) user.
    DOC
    def real_user
      return nil unless object["real_current_user_id"]
      Loaders::IDLoader.for(User).load(object["real_current_user_id"])
    end

    field :params, GraphQL::Types::JSON, null: true
  end
end
