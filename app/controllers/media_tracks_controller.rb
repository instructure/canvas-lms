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

# Partially an API

# @API Media Objects
# @subtopic Media Tracks
#
# Closed captions added to a video MediaObject
#
# @object MediaTrack
#   {
#     "id": 42,
#     "user_id": 1,
#     "media_object_id": 14,
#     "kind": "subtitles",
#     "locale": "es",
#     "content": "1]\\n00:00:00,000 --> 00:00:01,251\nI'm spanish",
#     "created_at": "Mon, 24 Feb 2020 16:04:02 EST -05:00",
#     "updated_at": "Mon, 24 Feb 2020 16:59:05 EST -05:00",
#     "webvtt_content": "WEBVTT\n\n1]\\n00:00:00.000 --> 00:00:01.251\nI'm spanish"
#   }
#
class MediaTracksController < ApplicationController
  include Api::V1::MediaObject
  include Api::V1::MediaTrack
  include FilesHelper

  before_action :load_media_object
  before_action :check_media_permissions, only: %i[index show]
  before_action only: %i[create destroy update] do
    check_media_permissions(access_type: :update)
  end

  TRACK_SETTABLE_ATTRIBUTES = %i[kind locale content].freeze

  # @API List media tracks for a Media Object or Attachment
  #
  # List the media tracks associated with a media object or attachment
  #
  # @argument include[] [String, "content"|"webvtt_content"|"updated_at"|"created_at"]
  #   By default, index returns id, locale, kind, media_object_id, and user_id for each of the
  #   result MediaTracks. Use include[] to
  #   add additional fields. For example include[]=content
  #
  # @example_request
  #     curl https://<canvas>/api/v1/media_objects/<media_object_id>/media_tracks?include[]=content
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/api/v1/media_attachments/<attachment_id>/media_tracks?include[]=content
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [MediaTrack]
  def index
    # assume that if I have access to the MediaObject, I can list its tracks
    media_tracks = if @attachment.present?
                     @attachment.media_tracks_include_originals
                   else
                     @media_object.media_tracks.where(user_id: @current_user.id)
                   end
    json_media_tracks = media_tracks.map { |t| media_track_api_json(t, params[:include]) }
    render json: json_media_tracks
  end

  # @{not an}API Create a media track
  #
  # Create a new media track to be used as captions for different languages or deaf users.
  # For more info, {https://developer.mozilla.org/en-US/docs/HTML/HTML_Elements/track read the MDN docs}
  #
  # @argument kind [String, "subtitles"|"captions"|"descriptions"|"chapters"|"metadata"]
  #   Default is 'subtitles'.
  #
  # @argument locale [String]
  #   Language code of the track being uploaded, examples: ["en", "es", "ru"]
  #
  # @argument content [String]
  #   The contents of the track, in SRT or WebVTT format
  #
  # @argument exclude[] [String, "tracks"]
  #   Exclude the given fields in the response.
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id>/media_tracks \
  #         -F kind='subtitles' \
  #         -F locale='es' \
  #         -F content='0\n00:00:00,000 --> 00:00:01,000\nInstructor…This is the first sentence\n\n\n1\n00:00:01,000 --> 00:00:04,000\nand a second...' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/media_attachments/<attachment_id>/media_tracks \
  #         -F kind='subtitles' \
  #         -F locale='es' \
  #         -F content='0\n00:00:00,000 --> 00:00:01,000\nInstructor…This is the first sentence\n\n\n1\n00:00:01,000 --> 00:00:04,000\nand a second...' \
  #
  # @returns MediaObject | MediaTrack
  def create
    if authorized_action(@media_object, @current_user, :add_captions)
      track = find_or_create_track(locale: params[:locale], attachment: @attachment, new_params: params)
      if @attachment.present?
        render json: media_track_api_json(track)
      else
        exclude = params[:exclude] || []
        render json: media_object_api_json(@media_object, @current_user, session, exclude)
      end
    end
  end

  # @{not an}API Get the content of a Media Track
  #
  # returns the actual content of the uploaded media track.
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id>/media_tracks/<media_track_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/media_attachments/<attachment_id>/media_tracks/<id> \
  #          -H 'Authorization: Bearer <token>'
  #
  def show
    @media_track = find_track_from_media_object(track_id: params[:id]).first
    raise ActiveRecord::RecordNotFound unless @media_track.present?

    @media_track.validate! # in case this somehow got saved to the database in the xss-vulnerable TTML format
    if stale? etag: @media_track, last_modified: @media_track.updated_at.utc
      render plain: @media_track.webvtt_content
    end
  end

  # @{not an}API Delete a Media Track
  #
  # Deletes the media track.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/media_objects/<media_object_id>/media_tracks/<id> \
  #          -H 'Authorization: Bearer <token>'
  # @example_request
  #     curl -X DELETE https://<canvas>/media_attachments/<attachment_id>/media_tracks/<id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns MediaObject | MediaTrack
  def destroy
    if authorized_action(@media_object, @current_user, :delete_captions)
      @media_track = find_track_from_media_object(track_id: params[:id]).first
      raise ActiveRecord::RecordNotFound unless @media_track.present?

      if @media_track.destroy
        render json: if @attachment.present?
                       media_track_api_json(@media_track)
                     else
                       media_object_api_json(@media_object, @current_user, session)
                     end
      end
    end
  end

  # @API Update Media Tracks
  #
  # Replace the media tracks associated with a media object or attachment with
  # the array of tracks provided in the body.
  # Update will
  # delete any existing tracks not listed,
  # leave untouched any tracks with no content field,
  # and update or create tracks with a content field.
  #
  # @argument include[] [String, "content"|"webvtt_content"|"updated_at"|"created_at"]
  #   By default, an update returns id, locale, kind, media_object_id, and user_id for each of the
  #   result MediaTracks. Use include[] to
  #   add additional fields. For example include[]=content
  #
  # @example_request
  #   curl -X PUT https://<canvas>/api/v1/media_objects/<media_object_id>/media_tracks?include[]=content \
  #     -H 'Authorization: Bearer <token>'
  #     -d '[{"locale": "en"}, {"locale": "af","content": "1\r\n00:00:00,000 --> 00:00:01,251\r\nThis is the content\r\n"}]'
  #
  # @example_request
  #   curl -X PUT https://<canvas>/api/v1/media_attachments/<attachment_id>/media_tracks?include[]=content \
  #     -H 'Authorization: Bearer <token>'
  #     -d '[{"locale": "en"}, {"locale": "af","content": "1\r\n00:00:00,000 --> 00:00:01,251\r\nThis is the content\r\n"}]'
  #
  # @returns [MediaTrack]
  def update
    return unless @media_object.grants_all_rights?(@current_user, session, :add_captions, :delete_captions)

    new_tracks = JSON.parse(request.body.read) || []
    new_tracks_locales = new_tracks.pluck("locale")

    old_track_locales = media_object_tracks.pluck(:locale)
    removed_track_locales = old_track_locales - new_tracks_locales
    removed_tracks = media_object_tracks.where(locale: removed_track_locales)
    attachment = @attachment || @media_object.attachment

    # delete the tracks that don't exist in the new set
    removed_tracks.destroy_all

    # create or update the new tracks
    new_tracks.each do |t|
      # if the new track coming from the client has no content, it hasn't been updated. Leave it alone.
      next if t["content"].blank?

      find_or_create_track(locale: t["locale"],
                           attachment:,
                           new_params: ActionController::Parameters.new(t))
    end
    index
  end

  private

  def find_or_create_track(locale:, attachment:, new_params:)
    track = if @attachment.present?
              @attachment.media_tracks.where(media_object: @media_object, locale:).take
            else
              @media_object.media_tracks.where(user: @current_user,
                                               locale:,
                                               attachment_id: [nil, @media_object.attachment_id]).take
            end
    track ||= @media_object.media_tracks.new(user: @current_user, locale:)
    track.update!(attachment:, **new_params.permit(*TRACK_SETTABLE_ATTRIBUTES))
    track
  end

  def media_object_tracks
    if @attachment.present?
      @attachment.media_tracks_include_originals
    else
      @media_object.media_tracks
    end
  end

  def find_track_from_media_object(track_id:)
    media_object_tracks.where(id: track_id)
  end
end
