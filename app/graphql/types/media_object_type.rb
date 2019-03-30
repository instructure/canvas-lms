#
# Copyright (C) 2019 - present Instructure, Inc.
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
  VALID_MEDIA_TYPES = %w[
    audio
    video
  ].freeze

  class MediaType < Types::BaseEnum
    graphql_name 'MediaType'

    VALID_MEDIA_TYPES.each { |type| value(type) }
  end

  class MediaObjectType < ApplicationObjectType
    graphql_name 'MediaObject'

    implements GraphQL::Types::Relay::Node

    global_id_field :id
    field :_id, ID, 'legacy canvas id', null: false, method: :media_id

    field :can_add_captions, Boolean, null: true
    def can_add_captions
      object.grants_right?(current_user, session, :add_captions)
    end

    field :media_type, MediaType, null: true
    def media_type
      object.media_type if VALID_MEDIA_TYPES.include?(object.media_type)
    end

    field :title, String, null: true

    field :media_sources, [Types::MediaSourceType], null: true
  end
end