# frozen_string_literal: true

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
  class MediaSourceType < ApplicationObjectType
    graphql_name 'MediaSource'

    field :bitrate, String, null: true

    field :content_type, String, null: true

    field :file_ext, String, hash_key: :fileExt, null: true

    field :height, String, null: true

    field :is_original, String, hash_key: :isOriginal, null: true

    field :size, String, null: true

    field :url, Types::UrlType, null: true

    field :width, String, null: true
  end
end
