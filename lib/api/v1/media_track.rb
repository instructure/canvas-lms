# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Api::V1::MediaTrack
  def media_track_api_json(media_track, include = [])
    result = {
      id: media_track.id,
      locale: media_track.locale,
      kind: media_track.kind,
      media_object_id: media_track.media_object_id,
      user_id: media_track.user_id
    }
    if include.present?
      whitelist = %w[content webvtt_content updated_at created_at]
      include.each do |field|
        result[field] = media_track[field] if whitelist.include? field
      end
    end
    result
  end
end
