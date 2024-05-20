# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

API_MEDIA_OBJECT_JSON_OPTS = {
  only: %w[media_id created_at media_type].freeze,
}.freeze

module Api::V1::MediaObject
  def media_object_api_json(media_object, current_user, session, exclude = [])
    api_json(media_object, current_user, session, API_MEDIA_OBJECT_JSON_OPTS).tap do |json|
      json["title"] = media_object.guaranteed_title
      json["can_add_captions"] = media_object.grants_right?(current_user, session, :add_captions)
      json["media_sources"] = media_sources_json(media_object) unless exclude.include?("sources")
      json["embedded_iframe_url"] = media_object_iframe_url(media_object.media_id)

      unless exclude.include?("tracks")
        json["media_tracks"] = media_object.media_tracks.map do |track|
          api_json(track, current_user, session, only: %w[kind created_at updated_at id locale]).tap do |json2|
            json2[:url] = show_media_tracks_url(media_object.media_id, track.id)
          end
        end
      end
    end
  end

  def media_attachment_api_json(attachment, media_object, current_user, session, exclude = [], verifier: nil)
    api_json(media_object, current_user, session, API_MEDIA_OBJECT_JSON_OPTS).tap do |json|
      json["title"] = media_object.guaranteed_title
      json["can_add_captions"] = attachment.grants_right?(current_user, session, :update)
      json["media_sources"] = media_sources_json(media_object, attachment:, verifier:) unless exclude.include?("sources")
      json["embedded_iframe_url"] = media_attachment_iframe_url(attachment.id)

      unless exclude.include?("tracks")
        json["media_tracks"] = attachment.media_tracks_include_originals.map do |track|
          api_json(track, current_user, session, only: %w[kind created_at updated_at id locale inherited]).tap do |json2|
            json2[:url] = show_media_attachment_tracks_url(attachment.id, track.id)
          end
        end
      end
    end
  end

  def media_sources_json(media_object, attachment: nil, verifier: nil)
    media_object.media_sources&.map do |mo|
      if Account.site_admin.feature_enabled?(:authenticated_iframe_content)
        mo[:url] = if attachment
                     media_attachment_redirect_url(attachment.id, bitrate: mo[:bitrate], verifier:)
                   else
                     media_object_redirect_url(media_object.media_id, bitrate: mo[:bitrate])
                   end
      end
      mo[:src] = mo[:url]
      mo[:label] = "#{(mo[:bitrate].to_i / 1024).floor} kbps"
      mo
    end
  end
end
