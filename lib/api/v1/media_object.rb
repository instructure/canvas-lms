#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::MediaObject

  def media_object_api_json(media_object, current_user, session)
    hash = {}
    hash['can_add_captions'] = media_object.grants_right?(current_user, session, :add_captions)
    hash['media_sources'] = media_object.media_sources
    hash['media_tracks'] = media_object.media_tracks.map do |track|
      api_json(track, current_user, session, :only => %w(kind created_at updated_at id locale)).tap do |json|
        json.merge! :url => show_media_tracks_url(media_object.media_id, track.id)
      end
    end
    hash
  end

end